###---CREATES AND ECRYTPS THE S3 BUCKET------###
resource "aws_kms_key" "kms_key_for_encryotion" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = var.kms_key_period
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_kms_alias" "kms_key_alias" {
  name          = "alias/${var.kms_key_name}"
  target_key_id = aws_kms_key.kms_key_for_encryotion.key_id
}