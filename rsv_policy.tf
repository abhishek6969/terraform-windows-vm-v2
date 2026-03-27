#------------------------------------------------------------
# Backup Policy - Create or reference an existing one
#------------------------------------------------------------
resource "azurerm_backup_policy_vm" "enhanced" {
  count = var.create_backup_policy ? 1 : 0

  name                = var.backup_policy.name
  resource_group_name = var.lz_rg_name
  recovery_vault_name = var.recovery_vault_name
  policy_type         = var.backup_policy.policy_type
  instant_restore_retention_days = var.backup_policy.instant_restore_retention_daily_count

  timezone = var.backup_policy.timezone

  backup {
    frequency = var.backup_policy.backup_frequency
    time      = var.backup_policy.backup_time
  }

  retention_daily {
    count = var.backup_policy.retention_daily_count
  }


}

data "azurerm_backup_policy_vm" "enhanced" {
  count = var.create_backup_policy ? 0 : 1

  name                = var.backup_policy.name
  resource_group_name = var.lz_rg_name
  recovery_vault_name = var.recovery_vault_name
}

# Resolve backup policy ID regardless of create/reference mode
locals {
  backup_policy_id = var.create_backup_policy ? azurerm_backup_policy_vm.enhanced[0].id : data.azurerm_backup_policy_vm.enhanced[0].id
}
