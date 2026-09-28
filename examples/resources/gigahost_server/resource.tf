# Deploy an hourly-billed cloud server. Selectors are human-readable slugs,
# resolved against the live catalog at create time — list them with
# `gigahost deploy types|sizes|regions|os`.
resource "gigahost_account_ssh_key" "deploy" {
  name       = "deploy-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "gigahost_server" "web" {
  type     = "value"       # gigahost deploy types
  size     = "2c-4gb-40gb" # gigahost deploy sizes
  os       = "debian-12"   # gigahost deploy os
  hostname = "web01"
  ssh_keys = [gigahost_account_ssh_key.deploy.id]
  # region is optional while only one region exists; set e.g. region = "sfj"
}

output "web_ipv4" {
  value = gigahost_server.web.ip
}

# primary_ip_id can be wired straight into reverse DNS, no data source needed.
resource "gigahost_server_rdns" "web" {
  server_id = gigahost_server.web.id
  ip_id     = gigahost_server.web.primary_ip_id
  dns       = "web01.example.com"
}
