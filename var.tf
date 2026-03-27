#------------------------------------------------------------
# Resource Group
#------------------------------------------------------------
variable "create_resource_group" {
  description = "Whether to create the resource group"
  type        = bool
  default     = true
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "germanywestcentral"
}

#------------------------------------------------------------
# Virtual Machine
#------------------------------------------------------------
variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "tkinfyazadmin"
}

#------------------------------------------------------------
# Networking
#------------------------------------------------------------
variable "subnet_id" {
  description = "Subnet ID for the NIC"
  type        = string
}

variable "private_ip_address" {
  description = "Static private IP address for the NIC"
  type        = string
}

#------------------------------------------------------------
# Key Vault
#------------------------------------------------------------
variable "key_vault_id" {
  description = "Key Vault ID to retrieve the admin password from"
  type        = string
}

variable "admin_password_key_vault_secret_name" {
  description = "Name of the Key Vault secret containing the VM admin password"
  type        = string
}

#------------------------------------------------------------
# Source Image
#------------------------------------------------------------
variable "image_publisher" {
  description = "Source image publisher"
  type        = string
  default     = "MicrosoftWindowsServer"
}

variable "image_offer" {
  description = "Source image offer"
  type        = string
  default     = "WindowsServer"
}

variable "image_sku" {
  description = "Source image SKU"
  type        = string
  default     = "2022-datacenter-g2"
}

variable "image_version" {
  description = "Source image version"
  type        = string
  default     = "latest"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_D2ls_v5"
}   

#------------------------------------------------------------
# Tags
#------------------------------------------------------------
variable "tags" {
    description = "Tags to apply to resources"
    type        = map(string)
    default     = {}
  
}

#------------------------------------------------------------
# Patching & Maintenance
#------------------------------------------------------------
variable "patch_assessment_mode"{
    type = string
    default = "AutomaticByPlatform"
}

variable "patch_mode" {
    type = string
    default = "AutomaticByPlatform"
}

variable "bypass_platform_safety_checks_on_user_schedule_enabled" {
    type = bool
    default = true
}

variable "maintenance_configuration_id" {
  description = "ID of the maintenance configuration"
  type        = string
}

#------------------------------------------------------------
# Data Disks
#------------------------------------------------------------
variable "data_disks" {
  description = "List of data disks to attach to the VM"
  type = list(object({
    name                 = string
    disk_size_gb         = number
    storage_account_type = optional(string, "Standard_LRS")
    caching              = optional(string, "ReadOnly")
    lun                  = number
    create_option        = optional(string, "Empty")
  }))
  default = []
}



#------------------------------------------------------------
# Backup & Recovery
#------------------------------------------------------------
variable "recovery_vault_name" {
  description = "Name of the Recovery Services Vault"
  type        = string
}

variable "create_backup_policy" {
  description = "Whether to create the backup policy"
  type        = bool
  default     = true
}

variable "lz_rg_name" {
    description = "Name of the landing zone resource group"
    type        = string
  
}

variable "backup_policy" {
  description = "Backup policy configuration"
  type = object({
    name                  = string
    policy_type           = optional(string, "V2")
    timezone              = optional(string, "W. Europe Standard Time")
    backup_frequency      = optional(string, "Daily")
    backup_time           = optional(string, "01:00")
    retention_daily_count = optional(number, 7)
    instant_restore_retention_daily_count = optional(number, 3)
  })
  default = {
    name = "Enhanced-Daily-1AM-7d"
  }
}

#------------------------------------------------------------
# OS Disk
#------------------------------------------------------------
variable "os_disk_caching" {
  description = "Caching type for the OS disk"
  type        = string
  default     = "ReadOnly"
}

variable "os_disk_storage_account_type" {
  description = "Storage account type for the OS disk"
  type        = string
  default     = "StandardSSD_LRS"
  
}

variable "enable_vm_backup"{
  type = bool
  default = true
}
