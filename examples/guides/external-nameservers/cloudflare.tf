# End-to-end example: a .no domain registered with Gigahost but served
# by Cloudflare, with DNSSEC chained through Norid.
#
# Prerequisites:
#   * A Gigahost account and an existing zone for example.no
#   * A Cloudflare zone for example.no with DNSSEC enabled
#   * The `cloudflare` and `gigahost` providers both configured via
#     their respective environment variables
#
# Running `tofu apply` (or `terraform apply`) performs three actions
# in dependency order:
#
#   1. Cloudflare serves as the authoritative DNS host
#   2. Gigahost delegates example.no's nameservers to Cloudflare
#   3. Gigahost pushes Cloudflare's DS record to Norid, completing
#      the DNSSEC chain of trust

terraform {
  required_providers {
    gigahost = {
      source  = "kradalby/gigahost"
      version = "~> 0.0.1"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

# The Gigahost zone as returned by `gigahost dns zones list`.
data "gigahost_dns_zone" "example" {
  name = "example.no"
}

# Cloudflare's authoritative nameservers for the zone. The v5 provider looks
# a zone up by filter; `name` is read-only on the data source.
data "cloudflare_zone" "example" {
  filter = {
    name = "example.no"
  }
}

resource "gigahost_dns_nameservers" "example" {
  zone_id     = data.gigahost_dns_zone.example.id
  nameservers = data.cloudflare_zone.example.name_servers
}

# Read the DS record Cloudflare publishes for the zone.
data "cloudflare_zone_dnssec" "example" {
  zone_id = data.cloudflare_zone.example.id
}

resource "gigahost_dns_external_ds_records" "example" {
  # Wait for the NS delegation to land before touching DS records.
  depends_on = [gigahost_dns_nameservers.example]

  zone_id = data.gigahost_dns_zone.example.id

  ds_records = [
    {
      key_tag     = data.cloudflare_zone_dnssec.example.key_tag
      algorithm   = data.cloudflare_zone_dnssec.example.algorithm
      digest_type = data.cloudflare_zone_dnssec.example.digest_type
      digest      = data.cloudflare_zone_dnssec.example.digest
    },
  ]
}
