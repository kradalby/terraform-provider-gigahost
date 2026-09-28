data "gigahost_servers" "example" {}

output "server_ids" {
  value = [for s in data.gigahost_servers.example.servers : s.id]
}
