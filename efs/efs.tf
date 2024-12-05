###---------CREATES ELASRIC FILE SYSTEM FOR EKS NODES---------------####
resource "aws_efs_file_system" "rafay_efs_fs" {
  creation_token = var.creation_token
  encrypted      = true
  kms_key_id     = var.kms_key_arn

  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_efs_mount_target" "rafay_efs_mount_target" {
  count           = length(var.subnet_id)
  file_system_id  = aws_efs_file_system.rafay_efs_fs.id
  subnet_id       = var.subnet_id[count.index]
  security_groups = [aws_security_group.tf_efs_sg.id]
}

resource "aws_efs_access_point" "test" {
  file_system_id = aws_efs_file_system.rafay_efs_fs.id

  tags = merge(
    var.default_tags,
    {
    },
  )
}

###########------------------Security Group--------------------_###############
resource "aws_security_group" "tf_efs_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = -1

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
      "karpenter.sh/discovery" = var.cluster_name
    },
  )
}
