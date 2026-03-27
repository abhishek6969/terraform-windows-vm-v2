# Azure Windows Virtual Machine Module

This module deploys a Windows Virtual Machine in Azure with networking, managed data disks, automatic patching, and optional backup — all in one go.

## What it does

- Creates (or reuses) a **Resource Group**
- Deploys a **Windows VM** with a static private IP
- Pulls the admin password securely from **Azure Key Vault**
- Attaches additional **data disks** if needed
- Assigns a **maintenance configuration** for automatic patching
- Optionally creates a **backup policy** and protects the VM in a Recovery Services Vault

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.10 |
| azurerm | ~> 4.0 |

## Usage

```hcl
module "windows_vm" {
  source = "git::https://dev.azure.com/tkim-mscloud/ACF/_git/terraform-windows-vm-v2?ref=v1.0.1"

  resource_group_name = "rg-myapp-prod"
  location            = "germanywestcentral"
  vm_name             = "vm-myapp-01"

  subnet_id          = "/subscriptions/.../subnets/my-subnet"
  private_ip_address = "10.0.1.10"

  key_vault_id                         = "/subscriptions/.../vaults/my-kv"
  admin_password_key_vault_secret_name = "vm-admin-password"

  maintenance_configuration_id = "/subscriptions/.../maintenanceConfigurations/my-config"

  recovery_vault_name = "rsv-myapp"
  lz_rg_name          = "rg-landingzone"

  data_disks = [
    {
      name         = "vm-myapp-01-data01"
      disk_size_gb = 128
      lun          = 0
    }
  ]

  tags = {
    Environment = "Production"
    Owner       = "TeamA"
  }
}
```

## Variables

### Resource Group

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `resource_group_name` | Name of the resource group where the VM will live. | `string` | — | **yes** |
| `create_resource_group` | Set to `true` to create a new RG, or `false` to use an existing one. | `bool` | `true` | no |
| `location` | Azure region (e.g. `germanywestcentral`, `westeurope`). | `string` | `germanywestcentral` | no |

### Virtual Machine

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `vm_name` | Name of the virtual machine. Also used as prefix for related resources (NIC, disks). | `string` | — | **yes** |
| `vm_size` | VM size / SKU (e.g. `Standard_D2ls_v5`). Controls CPU, memory, and cost. | `string` | `Standard_D2ls_v5` | no |
| `admin_username` | Local administrator username on the VM. | `string` | `tkinfyazadmin` | no |

### Networking

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `subnet_id` | Full resource ID of the subnet to connect the VM to. | `string` | — | **yes** |
| `private_ip_address` | Static private IP to assign to the VM NIC. Must be within the subnet range. | `string` | — | **yes** |

### Key Vault (Admin Password)

The module retrieves the VM admin password from an existing Key Vault secret — no passwords in your code.

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `key_vault_id` | Full resource ID of the Key Vault that holds the password secret. | `string` | — | **yes** |
| `admin_password_key_vault_secret_name` | Name of the secret inside Key Vault that stores the admin password. | `string` | — | **yes** |

### OS Image

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `image_publisher` | Image publisher. | `string` | `MicrosoftWindowsServer` | no |
| `image_offer` | Image offer. | `string` | `WindowsServer` | no |
| `image_sku` | Image SKU (e.g. `2022-datacenter-g2`, `2019-datacenter-g2`). | `string` | `2022-datacenter-g2` | no |
| `image_version` | Image version. Use `latest` to always get the newest. | `string` | `latest` | no |

### OS Disk

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `os_disk_caching` | Caching mode for the OS disk (`None`, `ReadOnly`, `ReadWrite`). | `string` | `ReadOnly` | no |
| `os_disk_storage_account_type` | Disk type for the OS disk (`StandardSSD_LRS`, `Premium_LRS`, etc.). | `string` | `StandardSSD_LRS` | no |

### Data Disks

Attach zero or more additional data disks to the VM.

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `data_disks` | List of data disks. Each disk needs at least a `name`, `disk_size_gb`, and `lun`. See fields below. | `list(object)` | `[]` | no |

Each disk object accepts:

| Field | Description | Default |
|-------|-------------|---------|
| `name` | Disk resource name. | — (required) |
| `disk_size_gb` | Size in GB. | — (required) |
| `lun` | Logical unit number (unique per VM, starting at 0). | — (required) |
| `storage_account_type` | Disk type. | `Standard_LRS` |
| `caching` | Caching mode. | `ReadOnly` |
| `create_option` | How to create the disk. | `Empty` |

### Patching & Maintenance

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `maintenance_configuration_id` | Full resource ID of the maintenance configuration to apply to the VM. | `string` | — | **yes** |
| `patch_mode` | Patching mode for the VM. | `string` | `AutomaticByPlatform` | no |
| `patch_assessment_mode` | Assessment mode for patches. | `string` | `AutomaticByPlatform` | no |
| `bypass_platform_safety_checks_on_user_schedule_enabled` | Allow patching on a custom schedule. | `bool` | `true` | no |

### Backup & Recovery

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `enable_vm_backup` | Set to `true` to enable backup protection for the VM. | `bool` | `true` | no |
| `recovery_vault_name` | Name of the Recovery Services Vault. | `string` | — | **yes** |
| `lz_rg_name` | Resource group where the Recovery Services Vault lives (landing zone RG). | `string` | — | **yes** |
| `create_backup_policy` | Set to `true` to create a new backup policy, or `false` to use an existing one (matched by name). | `bool` | `true` | no |
| `backup_policy` | Backup policy settings. Only `name` is required; the rest have sensible defaults. | `object` | See below | no |

Default backup policy:

| Field | Default |
|-------|---------|
| `name` | `Enhanced-Daily-1AM-7d` |
| `policy_type` | `V2` |
| `timezone` | `W. Europe Standard Time` |
| `backup_frequency` | `Daily` |
| `backup_time` | `01:00` |
| `retention_daily_count` | `7` |
| `instant_restore_retention_daily_count` | `3` |

### Tags

| Variable | Description | Type | Default | Required |
|----------|-------------|------|---------|----------|
| `tags` | Key-value map of tags applied to all resources. | `map(string)` | `{}` | no |
