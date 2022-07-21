## OCI Network Firewall and Policy Reference: https://github.com/oracle/terraform-provider-oci/tree/master/examples/network_firewall 

# ------ OCI Network Firewall Policy
resource "oci_network_firewall_network_firewall_policy" "network_firewall_policy" {
    display_name = "network-firewall-policy-demo"
    compartment_id             = var.network_compartment_ocid
    security_rules {
        action = var.oci_network_firewall_policy_action
        condition {
        }
        name = "Allow-All"
    }
}

# ------ OCI Network Firewall
resource "oci_network_firewall_network_firewall" "network_firewall" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  network_firewall_policy_id = oci_network_firewall_network_firewall_policy.network_firewall_policy.id
  subnet_id      = local.use_existing_network ? var.oci_network_firewall_subnet_id : oci_core_subnet.oci_network_firewall_subnet[0].id

  depends_on = [
    oci_core_subnet.oci_network_firewall_subnet,
  ]
}