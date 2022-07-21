#Variables declared in this file must be declared in the marketplace.yaml

############################
#  Hidden Variable Group   #
############################
variable "tenancy_ocid" {
}

variable "region" {
}

############################
#  Compute Configuration   #
############################

variable "vm_display_name" {
  description = "Instance Name"
  default     = "client-vm"
}

variable "vm_display_name_application" {
  description = "Instance Name"
  default     = "application-vm"
}

variable "vm_compute_shape" {
  description = "Compute Shape"
  default     = "VM.Standard2.2"
}

variable "spoke_vm_compute_shape" {
  description = "Compute Shape"
  default     = "VM.Standard2.2"
}

variable "vm_flex_shape_ocpus" {
  description = "Flex Shape OCPUs"
  default     = 4
}

variable "spoke_vm_flex_shape_ocpus" {
  description = "Spoke VMs Flex Shape OCPUs"
  default     = 4
}
variable "availability_domain_name" {
  default     = ""
  description = "Availability Domain"
}

variable "availability_domain_number" {
  default     = 1
  description = "OCI Availability Domains: 1,2,3  (subject to region availability)"
}

variable "ssh_public_key" {
  description = "SSH Public Key String"
}

variable "instance_launch_options_network_type" {
  description = "NIC Attachment Type"
  default     = "PARAVIRTUALIZED"
}

############################
#  Network Configuration   #
############################

variable "network_strategy" {
  default = "Create New VCN and Subnet"
}

variable "oci_network_firewall_vcn_id" {
  default = ""
}

variable "application_vcn_id" {
  default = ""
}

variable "oci_network_firewall_vcn_display_name" {
  description = "Firewall VCN Name"
  default     = "firewall-vcn"
}

variable "oci_network_firewall_vcn_cidr_block" {
  description = "OCI Network Firewall VCN CIDR"
  default     = "10.10.0.0/16"
}

variable "oci_network_firewall_vcn_dns_label" {
  description = "Firewall VCN DNS Label"
  default     = "firewall"
}

variable "subnet_span" {
  description = "Choose between regional and AD specific subnets"
  default     = "Regional Subnet"
}

variable "oci_network_firewall_subnet_id" {
  default = ""
}

variable "oci_network_firewall_subnet_display_name" {
  description = "Firewall Subnet Name"
  default     = "firewall-subnet"
}

variable "oci_network_firewall_subnet_cidr_block" {
  description = "Firewall Subnet CIDR"
  default     = "10.10.0.0/24"
}

variable "oci_network_firewall_subnet_dns_label" {
  description = "Firewall Subnet DNS Label"
  default     = "firewall"
}

variable "client_subnet_id" {
  default = ""
}

variable "client_subnet_display_name" {
  description = "Client Subnet Name"
  default     = "client-subnet"
}

variable "client_subnet_cidr_block" {
  description = "Client Subnet CIDR"
  default     = "10.10.1.0/24"
}

variable "client_subnet_dns_label" {
  description = "Client Subnet DNS Label"
  default     = "client"
}

variable "server_subnet_id" {
  default = ""
}

variable "server_subnet_display_name" {
  description = "Server Subnet Name"
  default     = "server-subnet"
}

variable "server_subnet_cidr_block" {
  description = "Server Subnet CIDR"
  default     = "10.10.2.0/24"
}

variable "server_subnet_dns_label" {
  description = "Server Subnet DNS Label"
  default     = "server"
}

variable "application_vcn_cidr_block" {
  description = "Application VCN CIDR Block"
  default     = "10.20.0.0/16"
}

variable "application_vcn_dns_label" {
  description = "Spoke Application VCN DNS Label"
  default     = "application"
}

variable "application_vcn_display_name" {
  description = "Spoke Application VCN Display Name"
  default     = "spoke-application-vcn"
}

variable "application_compute_subnetA_id" {
  default = ""
}

variable "application_compute_subnetA_cidr_block" {
  description = "Application VCN Private Subnet"
  default     = "10.20.1.0/24"
}

variable "application_compute_subnetA_display_name" {
  description = "Application VCN Private Subnet Display Name"
  default     = "application-compute-subnetA"
}

variable "application_compute_subnetA_dns_label" {
  description = "Application VCN DNS Label"
  default     = "applicationA"
}

variable "application_compute_subnetB_id" {
  default = ""
}

variable "application_compute_subnetB_cidr_block" {
  description = "Application VCN Private SubnetA"
  default     = "10.20.2.0/24"
}

variable "application_compute_subnetB_display_name" {
  description = "Application VCN Private Subnet Display Name"
  default     = "application-compute-subnetB"
}

variable "application_compute_subnetB_dns_label" {
  description = "Application VCN DNS Label"
  default     = "applicationB"
}

############################
# Additional Configuration #
############################

variable "oci_network_firewall_policy_action" {
  description = "Security Policy Action"
  default     = "Allow"
}

############################
# Additional Configuration #
############################

variable "compute_compartment_ocid" {
  description = "Compartment where Compute and Marketplace subscription resources will be created"
}

variable "network_compartment_ocid" {
  description = "Compartment where Network resources will be created"
}

variable "nsg_whitelist_ip" {
  description = "Network Security Groups - Whitelisted CIDR block for ingress communication: Enter 0.0.0.0/0 or <your IP>/32"
  default     = "0.0.0.0/0"
}

variable "nsg_display_name" {
  description = "Network Security Groups - Name"
  default     = "cluster-security-group"
}

variable "web_nsg_display_name" {
  description = "Network Security Groups - Web"
  default     = "web-security-group"
}

variable "public_routetable_display_name" {
  description = "Public route table Name"
  default     = "UntrustRouteTable"
}

variable "private_routetable_display_name" {
  description = "Private route table Name"
  default     = "TrustRouteTable"
}

variable "drg_routetable_display_name" {
  description = "DRG route table Name"
  default     = "DRGRouteTable"
}

variable "use_existing_ip" {
  description = "Use an existing permanent public ip"
  default     = "Create new IP"
}

variable "template_name" {
  description = "Template name. Should be defined according to deployment type"
  default     = "prisma-sdwan"
}

variable "template_version" {
  description = "Template version"
  default     = "20200724"
}

######################
#    Enum Values     #   
######################
variable "network_strategy_enum" {
  type = map
  default = {
    CREATE_NEW_VCN_SUBNET   = "Create New VCN and Subnet"
    USE_EXISTING_VCN_SUBNET = "Use Existing VCN and Subnet"
  }
}

variable "subnet_type_enum" {
  type = map
  default = {
    transit_subnet    = "Private Subnet"
    MANAGEMENT_SUBENT = "Public Subnet"
  }
}

variable "nsg_config_enum" {
  type = map
  default = {
    BLOCK_ALL_PORTS = "Block all ports"
    OPEN_ALL_PORTS  = "Open all ports"
    CUSTOMIZE       = "Customize ports - Post deployment"
  }
}
