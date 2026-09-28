data "gigahost_bgp" "example" {}

output "asns" {
  value = data.gigahost_bgp.example.asns
}
