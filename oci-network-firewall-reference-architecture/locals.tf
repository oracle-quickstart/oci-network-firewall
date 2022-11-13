locals {
  use_existing_network = var.network_strategy == var.network_strategy_enum["USE_EXISTING_VCN_SUBNET"] ? true : false
  is_flex_shape        = var.vm_compute_shape == "VM.Standard.E3.Flex" || var.vm_compute_shape == "VM.Standard.E4.Flex" ? [var.vm_flex_shape_ocpus] : []
  is_spoke_flex_shape  = var.spoke_vm_compute_shape == "VM.Standard.E3.Flex" || var.vm_compute_shape == "VM.Standard.E4.Flex" ? [var.spoke_vm_flex_shape_ocpus] : []
}
