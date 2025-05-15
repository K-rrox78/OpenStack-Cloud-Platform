# Terraform configuration for OpenStack Cloud Platform
# This configures the OpenStack provider and defines VM deployment templates

# Configure the OpenStack Provider
terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "~> 1.48.0"
    }
  }
}

# Provider configuration
provider "openstack" {
  auth_url    = var.os_auth_url
  user_name   = var.os_username
  password    = var.os_password
  tenant_name = var.os_project_name
  region      = var.os_region
}

# Variables
variable "os_auth_url" {
  description = "OpenStack authentication URL"
  default     = "http://controller:5000/v3"
}

variable "os_username" {
  description = "OpenStack username"
  default     = "admin"
}

variable "os_password" {
  description = "OpenStack password"
  sensitive   = true
}

variable "os_project_name" {
  description = "OpenStack project name"
  default     = "admin"
}

variable "os_region" {
  description = "OpenStack region"
  default     = "RegionOne"
}

variable "linux_image_id" {
  description = "ID of the Linux image to use"
  type        = string
}

variable "windows_image_id" {
  description = "ID of the Windows image to use"
  type        = string
}

variable "flavor_small" {
  description = "ID of small flavor"
  type        = string
}

variable "flavor_medium" {
  description = "ID of medium flavor"
  type        = string
}

variable "flavor_large" {
  description = "ID of large flavor"
  type        = string
}

variable "network_id" {
  description = "ID of the network to deploy VMs"
  type        = string
}

variable "key_pair" {
  description = "SSH key pair to use for Linux VMs"
  type        = string
}

variable "security_group" {
  description = "Security group for VMs"
  default     = "default"
}

# Linux VM module
module "linux_vms" {
  source = "./modules/linux_vm"
  
  count           = var.linux_vm_count
  name_prefix     = var.linux_name_prefix
  image_id        = var.linux_image_id
  flavor_id       = var.linux_flavor_id
  network_id      = var.network_id
  key_pair        = var.key_pair
  security_groups = [var.security_group]
}

# Windows VM module
module "windows_vms" {
  source = "./modules/windows_vm"
  
  count           = var.windows_vm_count
  name_prefix     = var.windows_name_prefix
  image_id        = var.windows_image_id
  flavor_id       = var.windows_flavor_id
  network_id      = var.network_id
  security_groups = [var.security_group]
}

# Outputs
output "linux_vm_ips" {
  value = module.linux_vms[*].instance_ip
}

output "windows_vm_ips" {
  value = module.windows_vms[*].instance_ip
}
