output "resource_group_name" {
  description = "Resource group containing the Teleport app VM and managed identity."
  value       = azurerm_resource_group.this.name
}

output "vm_name" {
  description = "Name of the Linux VM running the Teleport Application Service."
  value       = azurerm_linux_virtual_machine.this.name
}

output "vm_public_ip" {
  description = "Public IP of the VM (no inbound ports opened by default; access via tsh ssh)."
  value       = azurerm_public_ip.this.ip_address
}

output "tsh_ssh_command" {
  description = "Convenience tsh ssh command (use once the node has joined the Teleport cluster)."
  value       = "tsh ssh ${var.admin_username}@${azurerm_linux_virtual_machine.this.name}"
}

# The full URI of the managed identity. This is the value to pass to
#   tctl users update <user> --set-azure-identities <uri>
# and to reference in the `azure_identities` field of a Teleport role.
output "managed_identity_id" {
  description = "Resource ID (URI) of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.teleport.id
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.teleport.client_id
}

output "managed_identity_principal_id" {
  description = "Principal (object) ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.teleport.principal_id
}

output "storage_account_name" {
  description = "Test storage account for verifying tsh az storage commands."
  value       = azurerm_storage_account.test.name
}

output "storage_container_name" {
  description = "Test blob container inside the test storage account."
  value       = azurerm_storage_container.test.name
}
