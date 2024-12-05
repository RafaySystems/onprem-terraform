data "aws_caller_identity" "current" {}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = var.subnet_name
  subnet_ids = var.subnet_id

  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_db_instance" "postgres_sql" {
  count                       = var.replication_db == "" ? 1 : 0
  identifier                  = var.identifier
  allocated_storage           = var.allocated_storage
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  db_name                     = var.db_name
  backup_retention_period     = var.backup_retention_period
  multi_az                    = var.multi_az
  storage_encrypted           = var.storage_encrypted
  username                    = var.username
  password                    = local.db_creds.password
  publicly_accessible         = var.publicly_accessible
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = var.final_snapshot_identifier
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids      = [aws_security_group.rds_security_group.id]
  allow_major_version_upgrade = var.db_major_version_upgrade
  auto_minor_version_upgrade  = var.db_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  kms_key_id                  = var.kms_key_id
  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-postgres"
    },
  )
}

resource "aws_db_instance" "postgres_sql_replica" {
  depends_on = [ aws_db_subnet_group.db_subnet_group ]
  count                       = var.replication_db != "" ? 1 : 0
  replicate_source_db         = var.replication_db
  identifier                  = var.identifier
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  backup_retention_period     = var.backup_retention_period
  multi_az                    = var.multi_az
  storage_encrypted           = var.storage_encrypted
  skip_final_snapshot         = var.skip_final_snapshot
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_security_group.id]
  allow_major_version_upgrade = var.db_major_version_upgrade
  auto_minor_version_upgrade  = var.db_minor_version_upgrade
  apply_immediately           = var.apply_immediately
  kms_key_id                  = var.kms_key_id != "" ? var.kms_key_id : "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:alias/aws/rds"
  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-postgres"
    },
  )
}

/* resource "aws_db_parameter_group" "db_pg" {
  name   = var.parameter_name
  family = "postgres13"

  parameter {
    name  = "log_connections"
    value = "1"
  }
} */

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
      Name                     = "${var.cluster_name}-rds-sg"
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
