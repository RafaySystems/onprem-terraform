############################################################
#Create the eks  IAM role to allow EKS service to manage
#other AWS services
##########################################################

resource "aws_iam_role" "eks-iamcluster-role" {
  name = var.eks_iam_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_policy" "eks-workernode-KMSCustomerManagedKey_Policy" {
  name = var.eks-workernode-kms_customermanagedkey_policy

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:CreateGrant",
            "kms:ListGrants",
            "kms:RevokeGrant"
          ],
          "Resource" : ["${var.kms_key_arn}"],
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource" : ["${var.kms_key_arn}"]
        }
      ]
    }
  )
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iamcluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks-iamcluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-workernode-KMSCustomerManagedKey_Policy" {
  policy_arn = aws_iam_policy.eks-workernode-KMSCustomerManagedKey_Policy.arn
  role       = aws_iam_role.eks-iamcluster-role.name
}

resource "aws_cloudwatch_log_group" "eks-log-group" {
  count             = var.creates_cloudwatch_log_group ? 1 : 0
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.retention_days
  tags = merge(
    var.default_tags,
    {
    },
  )
}

##########################################
#Create the eks cluster
#########################################
resource "aws_eks_cluster" "eks-cluster" {
  count    = var.eks_cluster_encryption ? 0 : 1
  name     = var.cluster_name
  version  = var.eks_cluster_version
  role_arn = aws_iam_role.eks-iamcluster-role.arn
  #enabled_cluster_log_types = var.eks_cluster_log_types

  vpc_config {
    subnet_ids              = var.create_vpc == true ? aws_subnet.private_subnet.*.id : var.private_subnets_ids
    security_group_ids      = [aws_security_group.cluster_security_group.id]
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_endpoint_public_access_cidr
  }

  tags = merge(
    var.default_tags,
    {
      Name                     = "${var.cluster_name}"
      "karpenter.sh/discovery" = var.cluster_name
    },
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.eks-log-group,
  ]
}

resource "aws_eks_cluster" "eks_cluster_encrypted" {
  count    = var.eks_cluster_encryption ? 1 : 0
  name     = var.cluster_name
  version  = var.eks_cluster_version
  role_arn = aws_iam_role.eks-iamcluster-role.arn
  #enabled_cluster_log_types = var.eks_cluster_log_types

  vpc_config {
    subnet_ids              = var.create_vpc == true ? aws_subnet.private_subnet.*.id : var.private_subnets_ids
    security_group_ids      = [aws_security_group.cluster_security_group.id]
    endpoint_private_access = var.eks_endpoint_private_access
    endpoint_public_access  = var.eks_endpoint_public_access
    public_access_cidrs     = var.eks_endpoint_public_access_cidr
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = var.encryption_resources
  }

  tags = merge(
    var.default_tags,
    {
      Name                     = "${var.cluster_name}"
      "karpenter.sh/discovery" = var.cluster_name
    },
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
    aws_cloudwatch_log_group.eks-log-group,
  ]
}

#########------SECURITY GROUPS---------------------##########

resource "aws_security_group" "cluster_security_group" {
  name_prefix = "${var.cluster_name}-sg"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : aws_vpc.vpc[0].id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.ingress_cidr_blocks
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.egress_cidr_blocks
  }

  tags = merge(
    var.default_tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    },
  )
}


##############################################
#eks workers roles
#############################################
resource "aws_iam_role" "eks-workernode-role" {
  name = var.eks_workernode_iam_role_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = merge(
    var.default_tags,
    {
    },
  )
}

#################################################
#eks worker role policies to attach
#################################################
resource "aws_iam_role_policy_attachment" "eks-workernode-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-workernode-role.name
}

resource "aws_iam_role_policy_attachment" "eks-workernode-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-workernode-role.name
}

resource "aws_iam_role_policy_attachment" "eks-workernode-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-workernode-role.name
}

resource "aws_iam_role_policy_attachment" "eks-workernode-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks-workernode-role.name
}

#####################################################
#An instance profile is a container for an IAM role
# that you can use to pass role information to an EC2 instance
#when the instance starts.
#####################################################
resource "aws_iam_instance_profile" "eks-workernode-profile" {
  name = "${var.cluster_name}-instanceprofile1"
  role = aws_iam_role.eks-workernode-role.name
  tags = merge(
    var.default_tags,
    {
    },
  )
}


##############################################
#Create the eks workers
##############################################

resource "aws_eks_node_group" "default-worker-nodes-group" {
  cluster_name    = var.cluster_name
  node_group_name = var.eks_cluster_node_group_name
  node_role_arn   = aws_iam_role.eks-workernode-role.arn
  subnet_ids      = var.create_vpc == true ? aws_subnet.nodes_private_subnet.*.id : var.nodes_private_subnets_ids
  instance_types  = var.instance_type
  capacity_type   = var.capacity_type

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_size
    min_size     = var.min_size
  }

  launch_template {
    name    = aws_launch_template.cluster.name
    version = aws_launch_template.cluster.latest_version

  }

  depends_on = [
    aws_eks_cluster.eks-cluster[0],
    aws_eks_cluster.eks_cluster_encrypted[0],
  ]
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.default_tags,
    {
      "Name"                                      = "${var.cluster_name}-workernode"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "karpenter.sh/discovery"                    = var.cluster_name
    },
  )

}


#####
# Launch Template with AMI
#####

data "aws_ssm_parameter" "bottlerocket_ami_parameter" {
  name = "/aws/service/bottlerocket/aws-k8s-${var.eks_cluster_version}/x86_64/latest/image_id"
}

data "aws_ssm_parameter" "amazon_ami_parameter" {
  name = "/aws/service/eks/optimized-ami/${var.eks_cluster_version}/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "cluster" {
  image_id               = var.ami_id != "" ? var.ami_id : var.bottleRocket_os ? data.aws_ssm_parameter.bottlerocket_ami_parameter.value : data.aws_ssm_parameter.amazon_ami_parameter.value
  name                   = var.launchtemp_name
  update_default_version = var.launchtemp_update_version

  key_name = var.ec2_ssh_key

  block_device_mappings {
    device_name = var.device_name

    ebs {
      volume_size = var.volume_size
      volume_type = var.volume_type
    }
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size = var.root_volume_size
      volume_type = var.root_volume_type
    }
  }

  vpc_security_group_ids = [aws_security_group.worker_security_group.id]

  tag_specifications {
    resource_type = var.resource_type

    tags = merge(
      var.default_tags,
      {
        "Name"                                      = "${var.cluster_name}-workernode"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      },
    )
  }
  tag_specifications {
    resource_type = "volume"

    tags = merge(
      var.default_tags,
      {
        "Name"                                      = "${var.cluster_name}-workernode"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      },
    )
  }
  tag_specifications {
    resource_type = "spot-instances-request"

    tags = merge(
      var.default_tags,
      {
        "Name"                                      = "${var.cluster_name}-workernode"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      },
    )
  }
  user_data = var.bottleRocket_os ? base64encode(templatefile("${path.module}/userdata.toml", { CLUSTER_NAME = var.cluster_name, endpoint = var.eks_cluster_encryption ? aws_eks_cluster.eks_cluster_encrypted[0].endpoint : aws_eks_cluster.eks-cluster[0].endpoint, certificate_authority = var.eks_cluster_encryption ? aws_eks_cluster.eks_cluster_encrypted[0].certificate_authority.0.data : aws_eks_cluster.eks-cluster[0].certificate_authority.0.data, USER_CUSTOM_COMMANDS = var.user_custom_commands })) : base64encode(templatefile("${path.module}/userdata.tpl", { CLUSTER_NAME = var.cluster_name, USER_CUSTOM_COMMANDS = var.user_custom_commands }))
}

#########------SECURITY GROUPS---------------------##########
resource "aws_security_group" "worker_security_group" {
  name_prefix = "${var.cluster_name}-workersg"
  vpc_id      = var.vpc_id != "" ? var.vpc_id : aws_vpc.vpc[0].id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.ingress_cidr_blocks
  }
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = var.ingress_cidr_blocks
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = var.egress_cidr_blocks
  }

  tags = merge(
    var.default_tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    },
  )
}



#-----------------------------#
#EKS Cluster kubeconfig       #
#-----------------------------#
resource "local_file" "kubeconfig" {
  content  = local.kubeconfig
  filename = "${var.path}/${var.cluster_name}-kubeconfig"
}

#-----------------------------#
#EKS config map aws auth      #
#-----------------------------#

resource "local_file" "config_map_aws_auth" {
  content  = local.config_map_aws_auth
  filename = "${var.path}/${var.cluster_name}-config_map_aws_auth"
}

#---------------------------#
# EKS OIDC CONFIGURATION    #
#---------------------------#
data "tls_certificate" "cluster" {
  depends_on = [
    aws_eks_cluster.eks-cluster[0],
    aws_eks_cluster.eks_cluster_encrypted[0],
  ]
  url = var.eks_cluster_encryption ? aws_eks_cluster.eks_cluster_encrypted[0].identity.0.oidc.0.issuer : aws_eks_cluster.eks-cluster[0].identity.0.oidc.0.issuer
}
resource "aws_iam_openid_connect_provider" "cluster" {
  depends_on = [
    aws_eks_cluster.eks-cluster[0],
    aws_eks_cluster.eks_cluster_encrypted[0],
  ]
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = concat([data.tls_certificate.cluster.certificates.0.sha1_fingerprint])
  url             = var.eks_cluster_encryption ? aws_eks_cluster.eks_cluster_encrypted[0].identity.0.oidc.0.issuer : aws_eks_cluster.eks-cluster[0].identity.0.oidc.0.issuer
  tags = merge(
    var.default_tags,
    {
    },
  )
}


data "aws_eks_cluster" "cluster" {
  name = var.eks_cluster_encryption ? aws_eks_cluster.eks_cluster_encrypted[0].id : aws_eks_cluster.eks-cluster[0].id
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.eks_cluster_encryption ? aws_eks_cluster.eks_cluster_encrypted[0].id : aws_eks_cluster.eks-cluster[0].id
}

# resource "null_resource" "kubeconfig_update" {

#   provisioner "local-exec" {
#     command     = "aws eks update-kubeconfig --name ${var.cluster_name}  --region ${var.region}"
#     interpreter = ["/usr/bin/env", "bash", "-c"] 
#   }
#   depends_on = [
#     aws_eks_cluster.eks-cluster
#   ]
# }

resource "aws_eks_addon" "aws-ebs-csi-driver" {
  depends_on = [
    aws_eks_node_group.default-worker-nodes-group
  ]
  cluster_name             = var.cluster_name
  addon_name               = var.ebs_addon_name
  addon_version            = var.ebs_addon_version
  resolve_conflicts        = var.ebs_resolve_conflicts
  service_account_role_arn = var.ebs_arn
}

##############################################
#Create the karpenter workers
##############################################

resource "aws_eks_node_group" "karpenter-worker-nodes-group" {
  cluster_name    = var.cluster_name
  count           = var.karpenter_enabled ? (var.karpenter_fargate_enabled ? 0 : 1) : 0
  node_group_name = var.karpenter_eks_cluster_node_group_name
  node_role_arn   = aws_iam_role.eks-workernode-role.arn
  subnet_ids              = var.create_vpc == true ? aws_subnet.nodes_private_subnet.*.id : var.nodes_private_subnets_ids
  instance_types          = var.karpenter_instance_type
  capacity_type           = var.capacity_type

scaling_config {
    desired_size = var.karpenter_desired_capacity
    max_size     = var.karpenter_max_size
    min_size     = var.karpenter_min_size
  }

  launch_template {
    name      = aws_launch_template.cluster.name
    version   = aws_launch_template.cluster.latest_version
  }

labels = {
    "node-type" = "worker"
    "node"      = "karpenter"
  }

  taint {
    key    = "node"
    value  = "karpenter"
    effect = "NO_SCHEDULE"
  }
}

resource "aws_eks_fargate_profile" "fargate_profile" {
  cluster_name           = var.cluster_name
  count                  = var.karpenter_enabled ? (var.karpenter_fargate_enabled ? 1 : 0) : 0
  fargate_profile_name   = var.fargate_profile_name
  pod_execution_role_arn = aws_iam_role.eks-fargate-pod.arn
  subnet_ids             = var.create_vpc == true ? aws_subnet.nodes_private_subnet.*.id : var.nodes_private_subnets_ids

  selector {
    namespace = "karpenter"
  }
}

resource "aws_iam_role" "eks-fargate-pod" {
  name = var.fargate_profile_name

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}
