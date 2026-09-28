variable "machines" {
  description = "Machines to create. Map key = hostname; add an entry for another."
  type = map(object({
    type = optional(string, "performance") # KVM 'value' is often out of stock
    size = optional(string, "2c-4gb-40gb")
  }))
}

variable "ssh_key_name" {
  description = "Name of an SSH key already on the Gigahost account."
  type        = string
}

variable "ssh_private_key_path" {
  description = "Private key matching ssh_key_name; drives the install over SSH."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "flake" {
  description = "Flake providing nixosConfigurations.gigahost. Defaults to ./nixcfg; point at your own to adopt."
  type        = string
  default     = null
}
