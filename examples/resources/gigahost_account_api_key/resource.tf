resource "gigahost_account_api_key" "example" {
  label = "terraform"

  permissions = {
    servers = {
      mode = "rw"
      all  = true
    }
    dns = {
      mode = "r"
      all  = true
    }
  }
}
