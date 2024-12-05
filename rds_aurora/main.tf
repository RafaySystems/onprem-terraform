resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.subnet_name
  subnet_ids = var.subnet_id

  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_rds_cluster" "cluster" {
  engine                      = var.engine
  engine_mode                 = "provisioned"
  engine_version              = var.engine_version
  cluster_identifier          = var.cluster_name
  master_username             = var.username
  master_password             = local.db_creds.password
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  backup_retention_period     = var.backup_retention_period
  skip_final_snapshot         = var.skip_final_snapshot
  vpc_security_group_ids      = [aws_security_group.rds_security_group.id]
  final_snapshot_identifier   = var.final_snapshot_identifier
  allow_major_version_upgrade = var.db_major_version_upgrade
  apply_immediately           = var.apply_immediately
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot
  database_name               = var.db_name
  deletion_protection         = var.deletion_protection
  storage_encrypted           = var.storage_encrypted
  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-postgres-aurora"
    },
  )
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  identifier                   = "${var.cluster_name}-${count.index}"
  count                        = var.num_cluster_instances
  cluster_identifier           = aws_rds_cluster.cluster.id
  instance_class               = var.instance_class
  engine                       = aws_rds_cluster.cluster.engine
  engine_version               = aws_rds_cluster.cluster.engine_version
  publicly_accessible          = var.publicly_accessible
  auto_minor_version_upgrade   = var.db_minor_version_upgrade
  performance_insights_enabled = var.performance_insights_enabled
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot
  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-postgres-aurora"
    },
  )
}


###########------------------Security Group--------------------_###############

resource "aws_security_group" "rds_security_group" {
  vpc_id = var.vpc_id
  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"

    cidr_blocks = var.ingress_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egress_cidr_blocks
  }

  tags = merge(
    var.default_tags,
    {
      Name                     = "${var.cluster_name}-rds-aurora-sg"
      "karpenter.sh/discovery" = var.cluster_name
    },
  )
}

resource "aws_security_group_rule" "instance_allowed" {
  count             = length(var.instance_ips) != 0 ? 1 : 0
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.instance_ips
  security_group_id = aws_security_group.rds_security_group.id
}
