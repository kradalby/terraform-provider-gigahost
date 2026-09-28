# List the account's uploaded ISOs; names feed gigahost_server.iso.
data "gigahost_isos" "all" {}

output "iso_names" {
  value = data.gigahost_isos.all.isos[*].name
}
