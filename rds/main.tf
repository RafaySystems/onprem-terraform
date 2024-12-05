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
  password                    = local.db_creds != null ? local.db_creds.password : random_password.password.result
  publicly_accessible         = var.publicly_accessible
  skip_final_snapshot         = var.skip_final_snapshot
  final_snapshot_identifier   = var.final_snapshot_identifier
  db_subnet_group_name        = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids      = [aws_security_group.rds_security_group.id]
  allow_major_version_upgrade = var.db_major_version_upgrade
  auto_minor_version_upgrade  = var.db_minor_version_upgrade
  apply_immediately           = var.apply_immediately
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
