# All SSH keys on the account.
data "gigahost_ssh_keys" "all" {}

output "ssh_key_ids" {
  value = [for k in data.gigahost_ssh_keys.all.keys : k.id]
}
