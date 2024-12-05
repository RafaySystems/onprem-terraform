resource "aws_route53_zone" "zone_for_controller" {
  count = var.creates_route53_zone ? 1 : 0
  name  = var.domain_name

  vpc {
    vpc_id = var.vpc_id
  }
  tags = merge(
    var.default_tags,
    {
    },
  )
}

resource "aws_route53_record" "records_controller_ui" {
  count           = length(var.record_name_ui)
  allow_overwrite = var.allow_overwrite
  name            = var.record_name_ui[count.index]
  ttl             = var.record_ttl
  type            = var.record_type
  zone_id         = var.creates_route53_zone ? aws_route53_zone.zone_for_controller[0].zone_id : var.zone_id

  records = [
    "ui.${var.domain_name}"
  ]
}

resource "aws_route53_record" "records_controller_backend" {
  count           = var.external_lb ? length(var.record_name_backend) : 0
  allow_overwrite = var.allow_overwrite
  name            = var.record_name_backend[count.index]
  ttl             = var.record_ttl
  type            = var.record_type
  zone_id         = var.creates_route53_zone ? aws_route53_zone.zone_for_controller[0].zone_id : var.zone_id

  records = [
    "backend.${var.domain_name}"
  ]
}

resource "aws_route53_record" "records_controller" {
  count           = var.external_lb ? 0 : length(var.record_name_backend)
  allow_overwrite = var.allow_overwrite
  name            = var.record_name_backend[count.index]
  ttl             = var.record_ttl
  type            = var.record_type
  zone_id         = var.creates_route53_zone ? aws_route53_zone.zone_for_controller[0].zone_id : var.zone_id

  records = [
    "ui.${var.domain_name}"
  ]
}