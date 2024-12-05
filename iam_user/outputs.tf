output "access_key" {
  value = local.db_creds.*.accesskey

}

output "secret_key" {
  value = local.db_creds.*.secretkey
}