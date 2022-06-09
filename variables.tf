variable "name" {
  description = "Name of your dev VM instance"
  type        = string
}

variable "user_data" {
  description = "The user data to provide when launching the instance"
  type        = string
  default     = null
}

variable "region" {
  description = "Region where you want to deploy the VM instance"
  type        = string
  default     = null
}

variable "type" {
  description = "Type of your VM instance"
  type        = string
  default     = "s1-2"
}

variable "image" {
  description = "Name of the VM image"
  type        = string
  default     = "Debian 11"
}

variable "security_groups" {
  description = "An array of one or more security group names to associate with the server (not working with OVH vRack)"
  type        = list(string)
  default     = ["default"]
}

variable "network" {
  description = "Network list of the instance"
  type        = map(object({ name = string, ipv4 = optional(string) }))
  default     = { public = { name = "Ext-Net" } }
}

variable "storage" {
  description = "Additional storage for the VM"
  type        = map(object({ type = optional(string), size = number }))
  default     = {}
}

variable "metadata" {
  description = "Metadata key/value pairs to make available from within the instance"
  type        = map(any)
  default     = {}
}

variable "dns_zone" {
  description = "Zone of your DNS (domain.ext)"
  type        = set(string)
  default     = []
}

variable "dns_ttl" {
  description = "TTL of the DNS VM record (IPV4 and IPV6)"
  type        = number
  default     = 3600
}

variable "ssh_key_path" {
  description = "Path of your SSH key"
  type        = string
  default     = "id_ecdsa.pub"
}

locals {
  name           = terraform.workspace != "default" ? "${terraform.workspace}-${var.name}" : var.name
  user_data      = "#cloud-config\nhostname: ${local.name}\nfqdn: ${var.name}.${length(var.dns_zone) > 0 ? element(tolist(var.dns_zone), 0) : "local"}"
  region         = var.region != null ? var.region : data.openstack_compute_availability_zones_v2.zones.region
  int_vm_storage = { for k, v in var.storage : k => v if v.size > 0 }
  ext_vm_storage = { for k, v in var.storage : k => v if v.size == 0 }
}