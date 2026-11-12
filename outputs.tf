output "resource_group_id" {
  value       = data.azurerm_resource_group.lab.id
  description = "The ID of the lab resource group"
}

#output "intern_group_id" {
#  value       = azuread_group.interns.object_id
#  description = "Object ID of the interns Entra ID group"
#}

output "intern_principal_id" {
  value       = azurerm_user_assigned_identity.intern_principal.principal_id
  description = "Principal ID of the test Managed Identity"
}