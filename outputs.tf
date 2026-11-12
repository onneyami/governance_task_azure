output "resource_group_id" {
  value       = data.azurerm_resource_group.lab.id
  description = "The ID of the lab resource group"
}

output "intern_group_id" {
  value       = azuread_group.interns.object_id
  description = "Object ID of the interns Entra ID group"
}