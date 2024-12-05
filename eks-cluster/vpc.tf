
#-----------------------------#
#create VPC resources         #
#-----------------------------#
/*==== The VPC ======*/
resource "aws_vpc" "vpc" {
  count                = var.create_vpc == true ? 1 : 0
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.default_tags,
    {
      "Name" = var.vpc_name
    },
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "${var.cluster_name}"
    },
  )
}

resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {

  for_each   = toset(var.additional_cidr_block)
  vpc_id     = join("", aws_vpc.vpc.*.id)
  cidr_block = each.key
}

/*==== Subnets ======*/
/* Internet gateway for the public subnet */
resource "aws_internet_gateway" "ig" {
  count  = var.create_vpc == true ? 1 : 0
  vpc_id = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id

  tags = merge(
    var.default_tags,
    {
    },
  )
}

/* Elastic IP for NAT */
resource "aws_eip" "nat_eip" {
  count      = var.create_vpc == true ? 1 : 0
  vpc        = var.enable_nat_vpc
  depends_on = [aws_internet_gateway.ig]
}

/* NAT */
resource "aws_nat_gateway" "nat" {
  count         = var.create_vpc == true ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.ig]

  tags = merge(
    var.default_tags,
    {
    },
  )
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  count  = var.create_vpc == true ? 1 : 0
  vpc_id = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id

}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  count  = var.create_vpc == true ? 1 : 0
  vpc_id = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id

  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_route" "public_internet_gateway" {
  count                  = var.create_vpc == true ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.ig[0].id
}

resource "aws_route" "private_nat_gateway" {
  count                  = var.create_vpc == true ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = var.destination_cidr_block
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = var.create_vpc == true ? length(var.public_subnets_cidr) : 0
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private" {
  count          = var.create_vpc == true ? length(var.private_subnets_cidr) : 0
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "node_private" {
  count          = var.create_vpc == true ? length(var.nodes_private_subnets_cidr) : 0
  subnet_id      = element(aws_subnet.nodes_private_subnet.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id
  count                   = var.create_vpc == true ? length(var.public_subnets_cidr) : 0
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    var.default_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "kubernetes.io/role/elb"                    = "1"
      "karpenter.sh/discovery"                    = var.cluster_name
    },
  )
}

/* Private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id                  = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id
  count                   = var.create_vpc == true ? length(var.private_subnets_cidr) : 0
  cidr_block              = element(var.private_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.public_ip_privatesubnet

  tags = merge(
    var.default_tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "shared"
      "karpenter.sh/discovery"                    = var.cluster_name
    },
  )
}

resource "aws_subnet" "nodes_private_subnet" {
  vpc_id                  = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id
  count                   = var.create_vpc == true ? length(var.nodes_private_subnets_cidr) : 0
  cidr_block              = element(var.nodes_private_subnets_cidr, count.index)
  availability_zone       = element(var.azs, count.index)
  map_public_ip_on_launch = var.public_ip_privatesubnet

  tags = merge(
    var.default_tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    },
  )
}

/*==== VPC's Default Security Group ======*/
resource "aws_security_group" "vpc" {
  name        = "${var.cluster_name}-vpcsg"
  description = "Default security group to allow inbound/outbound from the VPC"
  vpc_id      = var.create_vpc == true ? "${aws_vpc.vpc[0].id}" : var.vpc_id
  # depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true

  }

  egress {
    from_port = "0"
    to_port   = "0"
    protocol  = "-1"
    self      = true

  }

  tags = merge(
    var.default_tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    },
  )
}

resource "aws_ec2_tag" "public_subnet_lb_tag" {
  count       = var.create_vpc == true ? length(var.public_subnets_cidr) : length(var.public_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.public_subnet[count.index].id : var.public_subnets_ids[count.index]
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "public_subnet_cluster_lb_tag" {
  depends_on = [
    aws_ec2_tag.public_subnet_lb_tag,
  ]
  count       = var.create_vpc == true ? length(var.public_subnets_cidr) : length(var.public_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.public_subnet[count.index].id : var.public_subnets_ids[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

resource "aws_ec2_tag" "private_subnet_lb_tag" {
  count       = var.create_vpc == true ? length(var.private_subnets_cidr) : length(var.private_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.private_subnet[count.index].id : var.private_subnets_ids[count.index]
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}
resource "aws_ec2_tag" "private_subnet_cluster_lb_tag" {
  depends_on = [
    aws_ec2_tag.private_subnet_lb_tag
  ]
  count       = var.create_vpc == true ? length(var.private_subnets_cidr) : length(var.private_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.private_subnet[count.index].id : var.private_subnets_ids[count.index]
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

###Adding tags in subnets for karpenter 
resource "aws_ec2_tag" "worker_node_private_subnet_cluster_karpenter_tag" {
  count       = var.create_vpc == true ? length(var.nodes_private_subnets_cidr) : length(var.nodes_private_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.nodes_private_subnet[count.index].id : var.nodes_private_subnets_ids[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "public_subnet_karpenter_tag" {
  depends_on = [
    aws_ec2_tag.public_subnet_lb_tag,
    aws_ec2_tag.public_subnet_cluster_lb_tag,
  ]
  count       = var.create_vpc == true ? length(var.public_subnets_cidr) : length(var.public_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.public_subnet[count.index].id : var.public_subnets_ids[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}

resource "aws_ec2_tag" "private_subnet_karpenter_tag" {
  depends_on = [
    aws_ec2_tag.private_subnet_lb_tag,
    aws_ec2_tag.private_subnet_cluster_lb_tag,
  ]
  count       = var.create_vpc == true ? length(var.private_subnets_cidr) : length(var.private_subnets_ids)
  resource_id = var.create_vpc == true ? aws_subnet.private_subnet[count.index].id : var.private_subnets_ids[count.index]
  key         = "karpenter.sh/discovery"
  value       = var.cluster_name
}
