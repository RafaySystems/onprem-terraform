output "super_password" {
  value = local.super_creds != null ? local.super_creds.password : random_password.super_password.result
}