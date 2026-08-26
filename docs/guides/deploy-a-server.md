---
page_title: "Deploy a cloud server with SSH"
subcategory: "Guides"
description: |-
  Deploy an hourly-billed Gigahost cloud server, inject an SSH key, point DNS at
  it, and change the OS in place.
---

# Deploy a cloud server with SSH

This guide walks through provisioning a server end to end: picking a size,
injecting an SSH key, deploying, wiring DNS and reverse DNS, and reinstalling
the OS in place. Everything is selected by human-readable slugs — no catalog
IDs anywhere.

## 1. Pick a type, size, and OS

The valid slugs come from the live catalog. List them with the CLI:

```console
$ gigahost deploy types     # value, performance, ...
$ gigahost deploy sizes     # 2c-4gb-40gb, 4c-8gb-80gb, ...
$ gigahost deploy os        # debian-12, ubuntu-24.04, ...
$ gigahost deploy regions   # sfj, ...
```

Or stay in Terraform and select by hardware criteria:

```terraform
data "gigahost_server_size" "small" {
  memory_gb = 4
  cheapest  = true
}

data "gigahost_operating_system" "debian" {
  distribution = "debian"
  release      = "12"
}
```

## 2. Register an SSH key and deploy

The server references the SSH key via the dependency graph, so the key is created
first and injected at provisioning time:

```terraform
resource "gigahost_account_ssh_key" "deploy" {
  name       = "deploy-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "gigahost_server" "web" {
  type     = "value"
  size     = "2c-4gb-40gb"
  os       = "debian-12"
  hostname = "web01"
  ssh_keys = [gigahost_account_ssh_key.deploy.id]
  # region is optional while the size is offered in exactly one region.
}

output "web_ipv4" {
  value = gigahost_server.web.ip
}
```

The slugs resolve against the live catalog at create time; a typo fails the
apply with a message listing the valid values. `tofu apply` deploys the server
and waits until it is ready; `web.ip`, `web.ipv6` and the sensitive
`web.password` are then available, along with the resolved `region`,
`memory_gb`, `storage_gb`, and `rate_hourly`.

The typed variant wires the data sources from step 1 instead:

```terraform
resource "gigahost_server" "web" {
  type     = data.gigahost_server_size.small.type
  size     = data.gigahost_server_size.small.slug
  os       = data.gigahost_operating_system.debian.slug
  hostname = "web01"
  ssh_keys = [gigahost_account_ssh_key.deploy.id]
}
```

## 3. Point DNS at the server

Use the computed `primary_ip_id` to set reverse DNS without a separate lookup, and
an A record for forward DNS:

```terraform
resource "gigahost_server_rdns" "web" {
  server_id = gigahost_server.web.id
  ip_id     = gigahost_server.web.primary_ip_id
  dns       = "web01.example.no"
}

resource "gigahost_dns_zone" "example" {
  name = "example.no"
  type = "NATIVE"
}

resource "gigahost_dns_record" "web" {
  zone_id = gigahost_dns_zone.example.id
  name    = "web01"
  type    = "A"
  value   = gigahost_server.web.ip
  ttl     = 300
}
```

## 4. Change the OS in place (optional)

Changing `gigahost_server.os` between two OS slugs reinstalls the server
**in place**: the server keeps its ID and IP, but **the disk is wiped** and SSH
keys are not re-injected. The plan emits a warning spelling this out before you
apply. Transitions involving `iso` or `rescue` replace the server instead.

```terraform
resource "gigahost_server" "web" {
  # ...
  os = "debian-13" # was "debian-12" — applying reinstalls in place, same IP
}
```

## 5. Tear down

`tofu destroy` cancels the server (stopping hourly billing) and removes the DNS and
SSH-key resources.
