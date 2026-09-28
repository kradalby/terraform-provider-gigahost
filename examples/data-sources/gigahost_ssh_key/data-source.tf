# Reference an SSH key created outside Terraform by name.
data "gigahost_ssh_key" "laptop" {
  name = "laptop"
}

resource "gigahost_server" "web" {
  type     = "value"
  size     = "2c-4gb-40gb"
  os       = "debian-12"
  ssh_keys = [data.gigahost_ssh_key.laptop.id]
}
