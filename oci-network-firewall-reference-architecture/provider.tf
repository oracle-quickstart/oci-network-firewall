# ---- Terraform Version
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    oci = {
      source                = "hashicorp/oci"
      version               = ">= 4.80.0"
    }
  }
} 

# Variables required by the OCI Provider only when running Terraform CLI with standard user based Authentication
variable "user_ocid" {
}

variable "fingerprint" {
}

variable "private_key_path" {
}
