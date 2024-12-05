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
