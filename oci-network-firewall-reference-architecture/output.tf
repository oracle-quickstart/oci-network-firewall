output "oci_network_firewall_client_instance_public_ip" {
  value = [oci_core_instance.client-vm[0].*.public_ip]
}

output "initial_instruction" {
value = <<EOT
1. Launch console connection. 
2. Configure OCI Network Firewall from GUI. 
3. For additional details follow the official documentation.
EOT
}
