# Push DS records from an externally hosted DNS provider (e.g.
# Cloudflare) up to Norid via Gigahost, completing the DNSSEC chain
# of trust for a Gigahost-registered .no domain.
resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

resource "gigahost_dns_external_ds_records" "example" {
  zone_id = gigahost_dns_zone.example.id

  ds_records = [
    {
      key_tag     = 12345
      algorithm   = 13
      digest_type = 2
      digest      = "1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF1234567890ABCDEF"
    },
  ]
}
