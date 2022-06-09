# tf-vm-ovh

This terraform module allow you to create an OVH virtual machine with its disks, networks and DNS records

It can manage either newly disk(s) or existing one(s).

You can select over public / [private (vRack) networks](https://github.com/reneca/tf-net-vrack-ovh).

If you have OVH managed DNS, you can also add a public record for your VM in your managed zone.

## Providers to enable

Providers to enable are defined in the [OVH documentation](https://docs.ovh.com/us/en/public-cloud/how-to-use-terraform/):

```hcl
# Define providers and set versions
terraform {
required_version    = ">= 0.14.0" # Takes into account Terraform versions from 0.14.0
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

# Configure the OpenStack provider hosted by OVHcloud
provider "openstack" {
  auth_url    = "https://auth.cloud.ovh.net/v3/" # Authentication URL
  domain_name = "default" # Domain name - Always at 'default' for OVHcloud
  alias       = "ovh" # An alias
}

provider "ovh" {
  alias              = "ovh"
  endpoint           = "ovh-eu"
  application_key    = "<your_access_key>"
  application_secret = "<your_application_secret>"
  consumer_key       = "<your_consumer_key>"
}
```

## APIs to enable

| Name | Url |
|------|-----|
| OVH domain name | [OVH token generation page](https://www.ovh.com/auth/api/createToken?GET=/*&POST=/*&PUT=/*&DELETE=/*) |
| Openstack compute | [OpenRC file](https://docs.ovh.com/us/en/public-cloud/set-openstack-environment-variables/) |

# Sample

## Simple VM

```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name         = "dummy"
  ssh_key_path = "~/.ssh/id_ecdsa.pub"
}
```

## VM of another type in another region

The type and region can be overloaded to spawn a different VM type in a different region

```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name         = "dummy"
  metadata = {
    this = "that"
  }
  ssh_key_path = "~/.ssh/id_ecdsa.pub"
  type         = "b2-7"
  region       = "BHS5"
}
```

## VM with multiple disks

With the module you can create disk for the current instance.
In that case the disk size indicate its size in Go.

If the instance need to be link to an external created disk, put a size of 0 and indicate the disk name as the storage key.

The type of storage can also be specified to create high-speed storage (classic by default)

```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name = "dummy"
  storage = {
    # Clasic storage
    "stock" = {
      size = 10
    }
    # Already existing storage, link the VM to it
    "external" = {
      size = 0
    }
    # High speed storage
    "sonic" = {
      size = 10
      type = "high-speed"
    }
  }
}
```

## VM with custom network

You can select the `network` or the `security-groups` of your VM.
OVH don't handle security-groups on private vRack network.

The "Ext-Net" is to have a public interface, and the other network is for vRack (need to be define before)

There is a [vRack module](https://github.com/reneca/tf-net-vrack-ovh.git) to deploy a private vRack network with its subnets. (See the module for the declaration)

```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name       = "dummy"
  network = {
    public = {
      name = "Ext-Net"
    }
    private = {
      name = "${module.dev-net.net_name}"
    }
  }
  depends_on = [module.dev-net.subnets]
}
```

The IPv4 can also be define on the private network:
```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name       = "dummy"
  network = {
    public = {
      name = "Ext-Net"
    }
    private = {
      name = "${module.dev-net.net_name}"
      ipv4 = "10.0.0.1"
    }
  }
  depends_on = [module.dev-net.subnets]
}
```

And if you want to use multiple security group with only a public network interface

```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name            = "dummy"
  security_groups = ["default", "custom"]
}
```

## VM with its associate DNS record

To create an associated DNS record for the VM, the `dns_zone` can be specified with an OVH domain name (managed by OVH).

With the following sample, the VM will have 4 DNS records:
- dummy.example.fr IN A <vm_ipv4_address>
- dummy.example.fr IN AAAA <vm_ipv6_address>
- dummy.example.com IN A <vm_ipv4_address>
- dummy.example.com IN AAAA <vm_ipv6_address>

```hcl
module "vm" {
  source = "git::https://github.com/reneca/tf-vm-ovh.git?ref=main"
  providers = {
    openstack = openstack.ovh
    ovh       = ovh.ovh
  }

  name     = "dummy"
  dns_zone = ["example.fr", "example.com"]
}
```

# Module specifications

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.0 |
| <a name="requirement_openstack"></a> [openstack](#requirement\_openstack) | ~> 1.42.0 |
| <a name="requirement_ovh"></a> [ovh](#requirement\_ovh) | >= 0.13.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_openstack"></a> [openstack](#provider\_openstack) | ~> 1.42.0 |
| <a name="provider_ovh"></a> [ovh](#provider\_ovh) | >= 0.13.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [openstack_blockstorage_volume_v2.volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/blockstorage_volume_v2) | resource |
| [openstack_compute_instance_v2.instance](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_instance_v2) | resource |
| [openstack_compute_keypair_v2.ssh_keypair](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_keypair_v2) | resource |
| [openstack_compute_volume_attach_v2.ext_volume_attach](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_volume_attach_v2) | resource |
| [openstack_compute_volume_attach_v2.int_volume_attach](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/resources/compute_volume_attach_v2) | resource |
| [ovh_domain_zone_record.ipv4_zone_record](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/domain_zone_record) | resource |
| [ovh_domain_zone_record.ipv6_zone_record](https://registry.terraform.io/providers/ovh/ovh/latest/docs/resources/domain_zone_record) | resource |
| [openstack_blockstorage_volume_v2.volume](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/blockstorage_volume_v2) | data source |
| [openstack_compute_availability_zones_v2.zones](https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs/data-sources/compute_availability_zones_v2) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_ttl"></a> [dns\_ttl](#input\_dns\_ttl) | TTL of the DNS VM record (IPV4 and IPV6) | `number` | `3600` | no |
| <a name="input_dns_zone"></a> [dns\_zone](#input\_dns\_zone) | Zone of your DNS (domain.ext) | `set(string)` | `[]` | no |
| <a name="input_image"></a> [image](#input\_image) | Name of the VM image | `string` | `"Debian 11"` | no |
| <a name="input_metadata"></a> [metadata](#input\_metadata) | Metadata key/value pairs to make available from within the instance | `map(any)` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of your dev VM instance | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Network list of the instance | `map(object({ name = string, ipv4 = optional(string) }))` | <pre>{<br>  "public": {<br>    "name": "Ext-Net"<br>  }<br>}</pre> | no |
| <a name="input_region"></a> [region](#input\_region) | Region where you want to deploy the VM instance | `string` | `null` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | An array of one or more security group names to associate with the server (not working with OVH vRack) | `list(string)` | <pre>[<br>  "default"<br>]</pre> | no |
| <a name="input_ssh_key_path"></a> [ssh\_key\_path](#input\_ssh\_key\_path) | Path of your SSH key | `string` | `"id_ecdsa.pub"` | no |
| <a name="input_storage"></a> [storage](#input\_storage) | Additional storage for the VM | `map(object({ type = optional(string), size = number }))` | `{}` | no |
| <a name="input_type"></a> [type](#input\_type) | Type of your VM instance | `string` | `"s1-2"` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | The user data to provide when launching the instance | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_names"></a> [dns\_names](#output\_dns\_names) | DNS names of the spawned instance |
| <a name="output_dns_zone_name"></a> [dns\_zone\_name](#output\_dns\_zone\_name) | DNS zone => name of the spawned instance |
| <a name="output_public_ipv4"></a> [public\_ipv4](#output\_public\_ipv4) | IPV4s of the spawned instance |
| <a name="output_public_ipv6"></a> [public\_ipv6](#output\_public\_ipv6) | IPV6s of the spawned instance |
| <a name="output_region"></a> [region](#output\_region) | Region where the instance was spawned |
