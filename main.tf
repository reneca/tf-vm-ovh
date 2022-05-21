# Providers versions
terraform {
  required_version = ">= 0.14.0"                      # Terraform version from 0.14.0 to allow optionnal type
  experiments      = [module_variable_optional_attrs] # Allow optionnal for type
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.42.0"
    }

    ovh = {
      source  = "ovh/ovh"
      version = ">= 0.13.0"
    }
  }
}

# Get the compute region info to deploy
data "openstack_compute_availability_zones_v2" "zones" {}

# SSH Key to spawn instances with
resource "openstack_compute_keypair_v2" "ssh_keypair" {
  name       = "${local.name}-ssh_keypair"
  public_key = file(var.ssh_key_path)
  region     = local.region
}

# Spawn the instance
resource "openstack_compute_instance_v2" "instance" {
  name            = local.name
  image_name      = var.image
  flavor_name     = var.type
  key_pair        = openstack_compute_keypair_v2.ssh_keypair.name
  region          = local.region
  security_groups = var.security_groups
  dynamic "network" {
    for_each = var.network
    content {
      name = network.value
    }
  }
}

# Create a storage if needed
resource "openstack_blockstorage_volume_v2" "volume" {
  for_each    = local.int_vm_storage
  name        = "${local.name}-${each.key}"
  volume_type = try(each.value.volume_type, "classic")
  size        = each.value.size
  region      = local.region
}

# Attach created volume(s) to the spawned VM
resource "openstack_compute_volume_attach_v2" "int_volume_attach" {
  for_each    = openstack_blockstorage_volume_v2.volume
  instance_id = openstack_compute_instance_v2.instance.id
  volume_id   = each.value.id
  region      = local.region
}

# Get information about external storage to attch to the VM
data "openstack_blockstorage_volume_v2" "volume" {
  for_each = local.ext_vm_storage
  region   = local.region
}

## Atach already created volume(s) to the spawned VM
resource "openstack_compute_volume_attach_v2" "ext_volume_attach" {
  for_each    = data.openstack_blockstorage_volume_v2.volume
  instance_id = openstack_compute_instance_v2.instance.id
  volume_id   = each.value.id
  region      = local.region
}

# Add IPV4 DNS records for the spawning instance
resource "ovh_domain_zone_record" "ipv4_zone_record" {
  for_each  = var.dns_zone
  zone      = each.value
  subdomain = var.name
  fieldtype = "A"
  ttl       = var.dns_ttl
  target    = openstack_compute_instance_v2.instance.network.0.fixed_ip_v4
}

# Add IPV6 DNS records for the spawning instance
resource "ovh_domain_zone_record" "ipv6_zone_record" {
  for_each  = var.dns_zone
  zone      = each.value
  subdomain = var.name
  fieldtype = "AAAA"
  ttl       = var.dns_ttl
  target    = trim(openstack_compute_instance_v2.instance.network.0.fixed_ip_v6, "[]")
}