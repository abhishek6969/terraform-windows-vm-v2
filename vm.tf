#------------------------------------------------------------
# Network Interface
#------------------------------------------------------------
resource "azurerm_network_interface" "example" {
  name                = "${var.vm_name}-nic"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address
    
  }
  lifecycle {
    ignore_changes = [ tags ]
  }

}

#------------------------------------------------------------
# Retrieve Admin Password from Key Vault
#------------------------------------------------------------
data "azurerm_key_vault_secret" "admin_password" {
  name         = var.admin_password_key_vault_secret_name
  key_vault_id = var.key_vault_id
}

#------------------------------------------------------------
# Windows Virtual Machine
#------------------------------------------------------------
resource "azurerm_windows_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = local.resource_group_name
  location            = local.location
  size                = var.vm_size
  tags                = var.tags
  admin_username      = var.admin_username
  admin_password      = data.azurerm_key_vault_secret.admin_password.value
  patch_assessment_mode = var.patch_assessment_mode
  patch_mode = var.patch_mode
  bypass_platform_safety_checks_on_user_schedule_enabled = var.bypass_platform_safety_checks_on_user_schedule_enabled
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]

  boot_diagnostics {}

  os_disk {
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
  }

  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = var.image_version
  }
  lifecycle {
    ignore_changes = [ tags ]
  }
}

#------------------------------------------------------------
# Maintenance Configuration Assignment
#------------------------------------------------------------
resource "azurerm_maintenance_assignment_virtual_machine" "example" {
  location                     = local.location
  maintenance_configuration_id = var.maintenance_configuration_id
  virtual_machine_id           = azurerm_windows_virtual_machine.example.id
}

#------------------------------------------------------------
# Managed Data Disks
#------------------------------------------------------------
resource "azurerm_managed_disk" "data" {
  for_each = { for disk in var.data_disks : disk.name => disk }

  name                 = each.value.name
  location             = local.location
  resource_group_name  = local.resource_group_name
  storage_account_type = each.value.storage_account_type
  create_option        = each.value.create_option
  disk_size_gb         = each.value.disk_size_gb

  lifecycle {
    ignore_changes = [tags]
  }
}

#------------------------------------------------------------
# Data Disk Attachments
#------------------------------------------------------------
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = { for disk in var.data_disks : disk.name => disk }

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.example.id
  lun                = each.value.lun
  caching            = each.value.caching
}


#------------------------------------------------------------
# Backup Protection for the VM
#------------------------------------------------------------
resource "azurerm_backup_protected_vm" "vm1" {
  count = var.enable_vm_backup ? 1 : 0

  resource_group_name = var.lz_rg_name
  recovery_vault_name = var.recovery_vault_name
  source_vm_id        = azurerm_windows_virtual_machine.example.id
  backup_policy_id    = local.backup_policy_id
}
