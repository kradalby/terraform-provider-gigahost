# List every installable operating system as one flat list.
data "gigahost_operating_systems" "all" {}

# Narrow to one distribution; entries carry the slug for gigahost_server.os.
data "gigahost_operating_systems" "debian" {
  distribution = "debian"
}

output "debian_slugs" {
  value = data.gigahost_operating_systems.debian.operating_systems[*].slug
}
