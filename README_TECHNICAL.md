# Technical Documentation - Azure Windows VM Terraform Module

## Overview

This Terraform module provisions a production-ready Windows Virtual Machine on Microsoft Azure. The module is designed for reusability and follows infrastructure-as-code best practices.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Resource Group                          │
│  (Created or Referenced based on create_resource_group flag)    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────────┐                                           │
│  │  Network Interface│                                          │
│  │   (Static Private IP)                                        │
│  └────────┬─────────┘                                           │
│           │                                                     │
│  ┌────────▼─────────┐      ┌──────────────────┐                │
│  │  Windows VM      │◄─────│  Maintenance     │                │
│  │  (2022-DC by default)    │  Configuration   │                │
│  └────────┬─────────┘      └──────────────────┘                │
│           │                                                     │
│  ┌────────▼─────────┐                                           │
│  │  OS Disk         │                                           │
│  │  (StandardSSD)   │                                           │
│  └────────┬─────────┘                                           │
│           │                                                     │
│  ┌────────▼─────────┐                                           │
│  │  Data Disks      │ (Optional, 0 to many)                    │
│  │  (Managed Disks) │                                           │
│  └──────────────────┘                                           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  Landing Zone Resource Group (External)                         │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │  Recovery Services Vault                                 │   │
│  │  ┌────────────────────┐    ┌─────────────────────────┐   │   │
│  │  │  Backup Policy     │───►│  Protected VM Resource  │   │   │
│  │  │  (Enhanced V2)     │    │  (Optional)             │   │   │
│  │  └────────────────────┘    └─────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## File Structure

| File | Purpose |
|------|---------|
| `versions.tf` | Terraform and provider version constraints |
| `var.tf` | Variable definitions with types and defaults |
| `rg.tf` | Resource group creation or data source lookup |
| `vm.tf` | Core VM resources (NIC, VM, disks, backup) |
| `rsv_policy.tf` | Backup policy creation or data source lookup |
| `outputs.tf` | Module outputs for consumers |

## Resource Inventory

### Primary Resources

| Resource | Type | Purpose |
|----------|------|---------|
| `azurerm_resource_group.RG` | Conditional | Creates RG when `create_resource_group = true` |
| `azurerm_network_interface.example` | Always | Network interface with static private IP |
| `azurerm_windows_virtual_machine.example` | Always | Windows Server virtual machine |
| `azurerm_maintenance_assignment_virtual_machine.example` | Always | Links VM to maintenance configuration |
| `azurerm_managed_disk.data` | Conditional | Data disks (count based on `data_disks` variable) |
| `azurerm_virtual_machine_data_disk_attachment.data` | Conditional | Attaches data disks to VM |
| `azurerm_backup_policy_vm.enhanced` | Conditional | Creates backup policy when `create_backup_policy = true` |
| `azurerm_backup_protected_vm.vm1` | Conditional | Protects VM with backup when `enable_vm_backup = true` |

### Data Sources

| Data Source | Purpose |
|-------------|---------|
| `azurerm_resource_group.RG` | References existing RG when `create_resource_group = false` |
| `azurerm_key_vault_secret.admin_password` | Retrieves admin password from Key Vault |
| `azurerm_backup_policy_vm.enhanced` | References existing backup policy when `create_backup_policy = false` |

## Local Values

```hcl
locals {
  resource_group_name = var.create_resource_group ? azurerm_resource_group.RG[0].name : data.azurerm_resource_group.RG[0].name
  location            = var.create_resource_group ? azurerm_resource_group.RG[0].location : data.azurerm_resource_group.RG[0].location
  backup_policy_id    = var.create_backup_policy ? azurerm_backup_policy_vm.enhanced[0].id : data.azurerm_backup_policy_vm.enhanced[0].id
}
```

## Dependencies

### External Dependencies

- **Subnet**: An existing subnet is required (referenced by `subnet_id`)
- **Key Vault**: An existing Key Vault with the admin password secret
- **Maintenance Configuration**: An existing Azure maintenance configuration
- **Recovery Services Vault**: An existing RSV in the landing zone resource group

### Internal Dependencies

```
azurerm_network_interface.example
    └── azurerm_windows_virtual_machine.example
        ├── azurerm_maintenance_assignment_virtual_machine.example
        ├── azurerm_managed_disk.data (for_each)
        │   └── azurerm_virtual_machine_data_disk_attachment.data
        └── azurerm_backup_protected_vm.vm1
            └── azurerm_backup_policy_vm.enhanced or data.azurerm_backup_policy_vm.enhanced
```

## Configuration Details

### Networking

- **Private IP Allocation**: Static (not DHCP)
- **IP Configuration Name**: "internal"
- **Public IP**: None (private connectivity only)

### OS Configuration

- **Default Image**: Windows Server 2022 Datacenter Gen2
- **Admin Username**: `tkinfyazadmin` (configurable)
- **Admin Password**: Retrieved from Azure Key Vault

### Patching

| Setting | Default Value |
|---------|---------------|
| Patch Mode | `AutomaticByPlatform` |
| Assessment Mode | `AutomaticByPlatform` |
| Bypass Safety Checks | `true` |

### OS Disk

| Setting | Default Value |
|---------|---------------|
| Caching | `ReadOnly` |
| Storage Type | `StandardSSD_LRS` |

### Backup Policy (V2 Enhanced)

| Setting | Default Value |
|---------|---------------|
| Policy Type | `V2` |
| Frequency | `Daily` |
| Time | `01:00` |
| Timezone | `W. Europe Standard Time` |
| Daily Retention | 7 days |
| Instant Restore | 3 days |

## Conditional Logic Patterns

### Resource Group Pattern

```hcl
count = var.create_resource_group ? 1 : 0
```

Used for creating vs referencing existing resource groups.

### Backup Policy Pattern

```hcl
count = var.create_backup_policy ? 1 : 0
```

Used for creating vs referencing existing backup policies.

### Backup Protection Pattern

```hcl
count = var.enable_vm_backup ? 1 : 0
```

Used for enabling/disabling VM backup protection.

### Data Disk Pattern

```hcl
for_each = { for disk in var.data_disks : disk.name => disk }
```

Creates variable number of data disks based on input list.

## Input Validation

The module uses Terraform's optional() function with defaults:

```hcl
type = list(object({
  name                 = string
  disk_size_gb         = number
  storage_account_type = optional(string, "Standard_LRS")
  caching              = optional(string, "ReadOnly")
  lun                  = number
  create_option        = optional(string, "Empty")
}))
```

## Lifecycle Management

All resources include `ignore_changes` for tags:

```hcl
lifecycle {
  ignore_changes = [tags]
}
```

This prevents Terraform from reverting tag changes made outside of Terraform.

## State Considerations

### Critical State Dependencies

1. **Key Vault Secret**: The `data.azurerm_key_vault_secret` resource cannot be destroyed as it is a data source
2. **Backup Protection**: Removing `enable_vm_backup` will destroy backup protection; data retention depends on backup policy settings
3. **Data Disks**: Removing disks from `data_disks` list will destroy them and all data

### Import Scenarios

For importing existing resources:

```bash
# Import VM
terraform import module.windows_vm.azurerm_windows_virtual_machine.example /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/virtualMachines/{vm}

# Import NIC
terraform import module.windows_vm.azurerm_network_interface.example /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/networkInterfaces/{nic}

# Import Data Disk
terraform import 'module.windows_vm.azurerm_managed_disk.data["disk-name"]' /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Compute/disks/{disk}

# Import Backup Protected VM
terraform import module.windows_vm.azurerm_backup_protected_vm.vm1[0] /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.RecoveryServices/vaults/{rsv}/backupFabrics/Azure/protectionContainers/IaasVMContainer;iaasvmcontainerv2;{source-rg};{vm}/protectedItems/VM;iaasvmcontainerv2;{vm-rg};{vm}
```

## Security Considerations

1. **Password Management**: Admin password stored in Key Vault, never in code
2. **Network Isolation**: VM has no public IP; must access via private network or jump host
3. **Managed Identity**: Consider enabling system-assigned managed identity for Azure resource access

## Cost Optimization

| Component | Cost Impact | Optimization |
|-----------|-------------|--------------|
| VM Size | High | Right-size based on workload |
| OS Disk | Medium | StandardSSD for non-critical workloads |
| Data Disks | Medium | Standard_LRS for cost savings |
| Backup | Low-Medium | Adjust retention periods |
| Boot Diagnostics | Low | Uses managed storage (included) |

## Version Constraints

| Component | Version |
|-----------|---------|
| Terraform | >= 1.10 |
| AzureRM Provider | ~> 4.0 |

## Common Issues and Troubleshooting

### Issue: Key Vault Secret Not Found

**Cause**: The secret name is incorrect or the service principal lacks access.

**Solution**: Verify `admin_password_key_vault_secret_name` and ensure the running identity has `Get` and `List` permissions on secrets.

### Issue: Subnet Not Found

**Cause**: The `subnet_id` is invalid or the subnet has been deleted.

**Solution**: Verify the full resource ID format: `/subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnet}/subnets/{subnet}`

### Issue: Backup Protection Fails

**Cause**: RSV or policy does not exist when `create_backup_policy = false`.

**Solution**: Ensure the RSV and policy exist in the specified `lz_rg_name` resource group before applying.

### Issue: Data Disk LUN Conflict

**Cause**: Multiple data disks assigned the same LUN.

**Solution**: Ensure each disk in `data_disks` has a unique `lun` value starting from 0.

## Testing Recommendations

### Pre-deployment Validation

```bash
# Format check
terraform fmt -check

# Validation
terraform validate

# Plan review
terraform plan -out=plan.tfplan
```

### Post-deployment Verification

```bash
# Show current state
terraform show

# Verify specific resource
terraform state show azurerm_windows_virtual_machine.example