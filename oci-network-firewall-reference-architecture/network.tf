# ------ Create OCI Network Firewall VCN
resource "oci_core_vcn" "oci_network_firewall" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.oci_network_firewall_vcn_cidr_block
  dns_label      = var.oci_network_firewall_vcn_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.oci_network_firewall_vcn_display_name
}

# ------ Create IGW
resource "oci_core_internet_gateway" "igw" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  display_name   = "igw"
  vcn_id         = oci_core_vcn.oci_network_firewall[count.index].id
  enabled        = "true"
}

# ------ Create DRG
resource "oci_core_drg" "drg" {
  compartment_id = var.network_compartment_ocid
  display_name   = "${var.oci_network_firewall_vcn_display_name}-drg"
}

# ------ Attach DRG to Firewall VCN
resource "oci_core_drg_attachment" "hub_drg_attachment" {
  drg_id             = oci_core_drg.drg.id
  display_name       = "Firewall-VCN-Attachment"
  drg_route_table_id = oci_core_drg_route_table.from_firewall_route_table.id

  network_details {
    id             = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall.0.id
    type           = "VCN"
    route_table_id = oci_core_route_table.vcn_ingress_route_table.0.id
  }
}

# ------ Attach DRG to Web Application Spoke VCN
resource "oci_core_drg_attachment" "web_drg_attachment" {
  drg_id             = oci_core_drg.drg.id
  vcn_id             = local.use_existing_network ? var.application_vcn_id : oci_core_vcn.application.0.id
  display_name       = "Application-VCN-Attachment"
  drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
}

# ------ DRG From Firewall Route Table
resource "oci_core_drg_route_table" "from_firewall_route_table" {
  drg_id                           = oci_core_drg.drg.id
  display_name                     = "From-Firewall"
  import_drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
}

# ------ DRG to Firewall Route Table
resource "oci_core_drg_route_table" "to_firewall_route_table" {
  drg_id       = oci_core_drg.drg.id
  display_name = "To-Firewall"
}

# ------ Add DRG To Firewall Route Table Entry
resource "oci_core_drg_route_table_route_rule" "to_firewall_drg_route_table_route_rule" {
  drg_route_table_id = oci_core_drg_route_table.to_firewall_route_table.id
  # destination                = var.branch_cidr
  destination                = "0.0.0.0/0"
  destination_type           = "CIDR_BLOCK"
  next_hop_drg_attachment_id = oci_core_drg_attachment.hub_drg_attachment.id
}

# ---- DRG Route Import Distribution 
resource "oci_core_drg_route_distribution" "firewall_drg_route_distribution" {
  distribution_type = "IMPORT"
  drg_id            = oci_core_drg.drg.id
  display_name      = "app-import-route"
}

# ---- DRG Route Import Distribution Statements - One
resource "oci_core_drg_route_distribution_statement" "firewall_drg_route_distribution_statement_one" {
  drg_route_distribution_id = oci_core_drg_route_distribution.firewall_drg_route_distribution.id
  action                    = "ACCEPT"
  match_criteria {
    match_type        = "DRG_ATTACHMENT_ID"
    drg_attachment_id = oci_core_drg_attachment.web_drg_attachment.id
  }
  priority = "1"
}

# ------ Default Routing Table for Firewall VCN 
resource "oci_core_default_route_table" "default_route_table" {
  count                      = local.use_existing_network ? 0 : 1
  manage_default_resource_id = oci_core_vcn.oci_network_firewall[count.index].default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }

}

# ------ Create Firewall VCN Ingress Route Table
resource "oci_core_route_table" "vcn_ingress_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oci_network_firewall[count.index].id
  display_name   = "FirewallVCNIngressRouteTable"

  route_rules {
    destination       = "10.20.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.firewall_subnet_private_ip.private_ips[0].id
  }

}

# ------ Get All Services Data Value 
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# ------ Get Hub Service Gateway from Gateways (Firewall VCN)
data "oci_core_service_gateways" "hub_service_gateways" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  state          = "AVAILABLE"
  vcn_id         = oci_core_vcn.oci_network_firewall[count.index].id
}

# ------ Create Firewall VCN: Firewall subnet
resource "oci_core_subnet" "oci_network_firewall_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oci_network_firewall[count.index].id
  cidr_block                 = var.oci_network_firewall_subnet_cidr_block
  display_name               = var.oci_network_firewall_subnet_display_name
  dns_label                  = var.oci_network_firewall_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_oci_network_firewall_core.security_lists[0].id]
  prohibit_public_ip_on_vnic = true

  depends_on = [
    oci_core_security_list.allow_oci_network_firewall_core_security,
  ]
}

# ------ Update Route Table for Firewall Subnet
resource "oci_core_route_table_attachment" "update_oci_network_firewall_core_route_table" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = local.use_existing_network ? var.oci_network_firewall_subnet_id : oci_core_subnet.oci_network_firewall_subnet[0].id
  route_table_id = oci_core_route_table.oci_network_firewall_core_route_table[count.index].id
}

# ------ Create Firewall VCN: Client subnet
resource "oci_core_subnet" "client_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oci_network_firewall[count.index].id
  cidr_block                 = var.client_subnet_cidr_block
  display_name               = var.client_subnet_display_name
  route_table_id             = oci_core_route_table.oci_network_firewall_client_route_table[count.index].id
  dns_label                  = var.client_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_oci_network_firewall_core.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_oci_network_firewall_core_security,
  ]
}

# ------ Create Firewall VCN: Server subnet
resource "oci_core_subnet" "server_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oci_network_firewall[count.index].id
  cidr_block                 = var.server_subnet_cidr_block
  display_name               = var.server_subnet_display_name
  route_table_id             = oci_core_route_table.oci_network_firewall_server_route_table[count.index].id
  dns_label                  = var.server_subnet_dns_label
  prohibit_public_ip_on_vnic = true
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_oci_network_firewall_core.security_lists[0].id]

  depends_on = [
    oci_core_security_list.allow_oci_network_firewall_core_security,
  ]
}

# ------ Create route table for Server Subnet Route Table (Firewall VCN)
resource "oci_core_route_table" "oci_network_firewall_server_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall[0].id
  display_name   = "ServerSubnetRouteTable"

  route_rules {
    destination       = "10.10.1.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.firewall_subnet_private_ip.private_ips[0].id
  }

  route_rules {
    destination       = "10.20.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.firewall_subnet_private_ip.private_ips[0].id
  }

}

# ------ Create route table for Client Subnet Route Table (Firewall VCN)
resource "oci_core_route_table" "oci_network_firewall_client_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall[0].id
  display_name   = "ClientSubnetRouteTable"

  route_rules {
    destination       = "10.10.2.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.firewall_subnet_private_ip.private_ips[0].id
  }

  route_rules {
    destination       = "10.20.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.firewall_subnet_private_ip.private_ips[0].id
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.igw[count.index].id
  }

}

# ------ Create route table for Firewall Subnet Route Table (Firewall VCN)
resource "oci_core_route_table" "oci_network_firewall_core_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall[0].id
  display_name   = "FirewallSubnetRouteTable"

  route_rules {
    destination       = "10.20.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

}

# ------ Add Firewall Subnet route table to Firewall subnet (Firewall VCN)
resource "oci_core_route_table_attachment" "oci_network_firewall_core_route_table_attachment" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = local.use_existing_network ? var.oci_network_firewall_subnet_id : oci_core_subnet.oci_network_firewall_subnet[0].id
  route_table_id = oci_core_route_table.oci_network_firewall_core_route_table[count.index].id
}

# ------ Create Application VCN
resource "oci_core_vcn" "application" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.application_vcn_cidr_block
  dns_label      = var.application_vcn_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.application_vcn_display_name
}

# ------ Update application spoke VCN route table
resource "oci_core_default_route_table" "application_default_route_table" {
  count                      = local.use_existing_network ? 0 : 1
  manage_default_resource_id = oci_core_vcn.application[count.index].default_route_table_id

  route_rules {
    network_entity_id = oci_core_drg.drg.id
    destination       = "10.20.0.0/16"
    destination_type  = "CIDR_BLOCK"
  }

}

# ------ Add Web Private Subnet to Web VCN
resource "oci_core_subnet" "application_compute_subnetA" {
  count                      = local.use_existing_network ? 0 : 1
  cidr_block                 = var.application_compute_subnetA_cidr_block
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.application[count.index].id
  display_name               = var.application_compute_subnetA_display_name
  dns_label                  = var.application_compute_subnetA_dns_label
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.server_subnet_a_route_table[count.index].id
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_application.security_lists[0].id]

  depends_on = [
    oci_core_security_list.allow_all_security_application,
  ]
}

# ------ Add Web Private Subnet to Web VCN
resource "oci_core_subnet" "application_compute_subnetB" {
  count                      = local.use_existing_network ? 0 : 1
  cidr_block                 = var.application_compute_subnetB_cidr_block
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.application[count.index].id
  display_name               = var.application_compute_subnetB_display_name
  dns_label                  = var.application_compute_subnetB_dns_label
  route_table_id             = oci_core_route_table.server_subnet_b_route_table[count.index].id
  prohibit_public_ip_on_vnic = true
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_application.security_lists[0].id]

  depends_on = [
    oci_core_security_list.allow_all_security_application,
  ]
}

# ------ Create route table for Firewall Subnet Route Table (Firewall VCN)
resource "oci_core_route_table" "server_subnet_a_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.application_vcn_id : oci_core_vcn.application[0].id
  display_name   = "ServerASubnetRouteTable"

  route_rules {
    destination       = "10.20.2.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
  
  route_rules {
    destination       = "10.10.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }
}

# ------ Create route table for Firewall Subnet Route Table (Firewall VCN)
resource "oci_core_route_table" "server_subnet_b_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.application_vcn_id : oci_core_vcn.application[0].id
  display_name   = "ServerBSubnetRouteTable"

  route_rules {
    destination       = "10.20.1.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

  route_rules {
    destination       = "10.10.0.0/16"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

}

# ------ Update Default Security List to All All  Rules
resource "oci_core_security_list" "allow_oci_network_firewall_core_security" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall.0.id
  display_name   = "AllowAll"

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}

# ------ Update Default Security List to All All  Rules
resource "oci_core_security_list" "allow_all_security_application" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.application_vcn_id : oci_core_vcn.application.0.id
  display_name   = "AllowAll"

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }
}
