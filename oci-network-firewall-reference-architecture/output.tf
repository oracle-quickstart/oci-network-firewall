output "client_instance_public_ip" {
  value = [oci_core_instance.client-vm[0].*.public_ip]
}

output "server_instance_private_ip" {
  value = [oci_core_instance.server-vm[0].*.private_ip]
}

output "serverA_instance_private_ip" {
  value = [oci_core_instance.application-vm-a[0].*.private_ip]
}

output "serverB_instance_private_ip" {
  value = [oci_core_instance.application-vm-b[0].*.private_ip]
}

output "oci_network_firewall_ip_address" {
  value = [data.oci_core_private_ips.firewall_subnet_private_ip.private_ips[0].ip_address]
}

output "initial_instruction" {
  value = <<EOT
1. Launch OCI Console connection. 
2. Review Topology and connect to Respective VMs. 
3. Update OCI Network Firewall configuration if needed from GUI/terraform. 
4. For additional details follow the official documentation: https://docs.oracle.com/en-us/iaas/Content/network-firewall/overview.htm 
EOT
}
