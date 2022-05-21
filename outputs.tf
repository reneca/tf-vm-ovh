output "region" {
  description = "Region where the instance was spawned"
  value       = local.region
}

# Output host IP
output "public_ipv4" {
  description = "IPV4s of the spawned instance"
  value       = [for net in openstack_compute_instance_v2.instance.network : net.fixed_ip_v4]
}

output "public_ipv6" {
  description = "IPV6s of the spawned instance"
  value       = [for net in openstack_compute_instance_v2.instance.network : trim(net.fixed_ip_v6, "[]")]
}

# Output host DNS
output "dns_zone_name" {
  description = "DNS zone => name of the spawned instance"
  value       = { for zone in var.dns_zone : zone => { "name" : var.name, "record" : "${var.name}.${zone}", "ipv4" : openstack_compute_instance_v2.instance.network.0.fixed_ip_v4, "ipv6" : trim(openstack_compute_instance_v2.instance.network.0.fixed_ip_v6, "[]") } }
}

output "dns_names" {
  description = "DNS names of the spawned instance"
  value       = [for zone in var.dns_zone : "${var.name}.${zone}"]
}