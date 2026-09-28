# List every record in a zone.
data "gigahost_dns_records" "example" {
  zone = "example.com"
}

output "record_names" {
  value = [for r in data.gigahost_dns_records.example.records : r.name]
}
