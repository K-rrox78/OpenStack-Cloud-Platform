# Terraform module for Linux VM deployment on OpenStack

variable "name_prefix" {
  description = "Prefix for VM names"
  type        = string
}

variable "count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "image_id" {
  description = "ID of the image to use"
  type        = string
}

variable "flavor_id" {
  description = "ID of the flavor to use"
  type        = string
}

variable "network_id" {
  description = "ID of the network to attach"
  type        = string
}

variable "key_pair" {
  description = "SSH key pair to use"
  type        = string
}

variable "security_groups" {
  description = "List of security groups"
  type        = list(string)
  default     = ["default"]
}

variable "user_data" {
  description = "User data for cloud-init"
  type        = string
  default     = ""
}

# Create the Linux VM
resource "openstack_compute_instance_v2" "linux_vm" {
  count           = var.count
  name            = "${var.name_prefix}-${count.index + 1}"
  image_id        = var.image_id
  flavor_id       = var.flavor_id
  key_pair        = var.key_pair
  security_groups = var.security_groups
  user_data       = var.user_data

  network {
    uuid = var.network_id
  }

  metadata = {
    os_type = "linux"
  }
}

# Create and assign floating IP if requested
resource "openstack_networking_floatingip_v2" "fip" {
  count = var.assign_floating_ip ? var.count : 0
  pool  = var.floating_ip_pool
}

resource "openstack_compute_floatingip_associate_v2" "fip_associate" {
  count       = var.assign_floating_ip ? var.count : 0
  floating_ip = openstack_networking_floatingip_v2.fip[count.index].address
  instance_id = openstack_compute_instance_v2.linux_vm[count.index].id
}

# Output the instance IPs
output "instance_ip" {
  value = var.assign_floating_ip ? 
    openstack_networking_floatingip_v2.fip[*].address : 
    openstack_compute_instance_v2.linux_vm[*].network[0].fixed_ip_v4
}

output "instance_id" {
  value = openstack_compute_instance_v2.linux_vm[*].id
}

# Added missing variable declaration
variable "assign_floating_ip" {
  description = "Whether to assign a floating IP"
  type        = bool
  default     = false
}

variable "floating_ip_pool" {
  description = "Name of the floating IP pool"
  type        = string
  default     = "public"
}
