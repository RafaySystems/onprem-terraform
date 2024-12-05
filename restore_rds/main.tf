
resource "aws_db_snapshot" "latest_prod_snapshot" {
  db_instance_identifier = var.db_instance_identifier_id
  db_snapshot_identifier = var.db_snapshot_identifier
  tags = merge(
    var.default_tags,
    {
    },
  )
}


resource "aws_db_instance" "restore_db" {
  identifier                = "${var.cluster_name}-postgres"
  snapshot_identifier       = aws_db_snapshot.latest_prod_snapshot.id
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  engine                    = var.engine
  engine_version            = var.engine_version
  backup_retention_period   = var.backup_retention_period
  multi_az                  = var.multi_az
  storage_encrypted         = var.storage_encrypted
  username                  = var.username
  password                  = local.db_creds.password
  final_snapshot_identifier = var.final_snapshot_identifier
  publicly_accessible       = var.publicly_accessible
  skip_final_snapshot       = var.skip_final_snapshot
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.rds_restored_security_group.id]

  lifecycle {
    ignore_changes = [snapshot_identifier]
  }
  tags = merge(
    var.default_tags,
    {
      Name = "${var.cluster_name}-postgres"
    },
  )
}
# Use the latest production snapshot to create a dev instance.

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.cluster_name}-db-subnet"
  subnet_ids = var.subnet_id

  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_security_group" "rds_restored_security_group" {
  name_prefix = "rds_sg"
  vpc_id      = var.vpc_id

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

resource "aws_security_group_rule" "instance_allowed_restore" {
  count             = length(var.instance_ips) != 0 ? 1 : 0
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = var.instance_ips
  security_group_id = aws_security_group.rds_restored_security_group.id
}