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

# ------ Attach DRG to Hub VCN
resource "oci_core_drg_attachment" "hub_drg_attachment" {
  drg_id             = oci_core_drg.drg.id
  display_name       = "oci-network-firewall-transit"
  drg_route_table_id = oci_core_drg_route_table.from_firewall_route_table.id

  network_details {
    id   = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall.0.id
    type = "VCN"
    route_table_id = oci_core_route_table.vcn_ingress_route_table.0.id
  }
}

# ------ Attach DRG to Web Application Spoke VCN
resource "oci_core_drg_attachment" "web_drg_attachment" {
  drg_id             = oci_core_drg.drg.id
  vcn_id             = local.use_existing_network ? var.application_vcn_id : oci_core_vcn.application.0.id
  display_name       = "Application-VCN"
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
  drg_route_table_id         = oci_core_drg_route_table.to_firewall_route_table.id
  destination                = var.branch_cidr
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
    match_type = "DRG_ATTACHMENT_ID"
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

# ------ Default Routing Table for Hub VCN 
resource "oci_core_route_table" "oci_network_firewall_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = oci_core_vcn.oci_network_firewall[count.index].id
  display_name   = "oci-network-firewall-public-rt"

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
  display_name   = "VCN-INGRESS"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_private_ips.oci_network_firewall_core_subnet_private_ips.private_ips[0].id
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

# ------ Create Firewal VCN Public subnet
resource "oci_core_subnet" "oci_network_firewall_public_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oci_network_firewall[count.index].id
  cidr_block                 = var.oci_network_firewall_public_subnet_cidr_block
  display_name               = var.oci_network_firewall_public_subnet_display_name
  route_table_id             = oci_core_route_table.oci_network_firewall_controller_route_table[count.index].id
  dns_label                  = var.oci_network_firewall_public_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_oci_network_firewall_public.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_oci_network_firewall_public_security,
  ]
}

# ------ Create Hub VCN Trust subnet
resource "oci_core_subnet" "oci_network_firewall_core_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oci_network_firewall[count.index].id
  cidr_block                 = var.oci_network_firewall_core_subnet_cidr_block
  display_name               = var.oci_network_firewall_core_subnet_display_name
  dns_label                  = var.oci_network_firewall_core_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_oci_network_firewall_core.security_lists[0].id]
  prohibit_public_ip_on_vnic = "true"

  depends_on = [
    oci_core_security_list.allow_oci_network_firewall_core_security,
  ]
}

# ------ Update Route Table for Trust Subnet
resource "oci_core_route_table_attachment" "update_oci_network_firewall_core_route_table" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = local.use_existing_network ? var.oci_network_firewall_core_subnet_id : oci_core_subnet.oci_network_firewall_core_subnet[0].id
  route_table_id = oci_core_route_table.oci_network_firewall_core_route_table[count.index].id
}

# ------ Create Hub VCN PAN Internet subnet
resource "oci_core_subnet" "oci_network_firewall_controller_subnet" {
  count                      = local.use_existing_network ? 0 : 1
  compartment_id             = var.network_compartment_ocid
  vcn_id                     = oci_core_vcn.oci_network_firewall[count.index].id
  cidr_block                 = var.oci_network_firewall_controller_subnet_cidr_block
  display_name               = var.oci_network_firewall_controller_subnet_display_name
  route_table_id             = oci_core_route_table.oci_network_firewall_controller_route_table[count.index].id
  dns_label                  = var.oci_network_firewall_controller_subnet_dns_label
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_oci_network_firewall_controller.security_lists[0].id]
  prohibit_public_ip_on_vnic = "false"

  depends_on = [
    oci_core_security_list.allow_oci_network_firewall_controller_security,
  ]
}

# ------ Create route table for backend to point to backend cluster ip (Hub VCN)
resource "oci_core_route_table" "oci_network_firewall_core_route_table" {
  count          = local.use_existing_network ? 0 : 1
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall[0].id
  display_name   = "prisma-sdwan-core-rt"

  route_rules {
    destination       = "172.16.0.0/24"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
  }

}

# ------ Add Trust route table to Trust subnet (Hub VCN)
resource "oci_core_route_table_attachment" "oci_network_firewall_core_route_table_attachment" {
  count          = local.use_existing_network ? 0 : 1
  subnet_id      = local.use_existing_network ? var.oci_network_firewall_core_subnet_id : oci_core_subnet.oci_network_firewall_core_subnet[0].id
  route_table_id = oci_core_route_table.oci_network_firewall_core_route_table[count.index].id
}

# ------ Create Web VCN
resource "oci_core_vcn" "application" {
  count          = local.use_existing_network ? 0 : 1
  cidr_block     = var.application_vcn_cidr_block
  dns_label      = var.application_vcn_dns_label
  compartment_id = var.network_compartment_ocid
  display_name   = var.application_vcn_display_name
}

# ------ Create Web Route Table and Associate to Web LPG
resource "oci_core_default_route_table" "application_default_route_table" {
  count                      = local.use_existing_network ? 0 : 1
  manage_default_resource_id = oci_core_vcn.application[count.index].default_route_table_id

  route_rules {
    network_entity_id = oci_core_drg.drg.id
    destination       = "172.16.255.0/24"
    destination_type  = "CIDR_BLOCK"
  }

  route_rules {
    destination       = var.branch_sdwan_supernet
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_drg.drg.id
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
  prohibit_public_ip_on_vnic = true
  security_list_ids          = [data.oci_core_security_lists.allow_all_security_application.security_lists[0].id]

  depends_on = [
    oci_core_security_list.allow_all_security_application,
  ]
}

# ------ Update Default Security List to All All  Rules
resource "oci_core_security_list" "allow_oci_network_firewall_public_security" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall.0.id
  display_name   = "firewall-vcn-public-sl"
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
resource "oci_core_security_list" "allow_oci_network_firewall_core_security" {
  compartment_id = var.network_compartment_ocid
  vcn_id         = local.use_existing_network ? var.oci_network_firewall_vcn_id : oci_core_vcn.oci_network_firewall.0.id
  display_name   = "firewall-vcn-core-sl"
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