# Standard Built-in Role Assignment
resource "azurerm_role_assignment" "interns_reader" {
  scope                = azurerm_resource_group.lab.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.interns.object_id
}

# Custom Role Definition with Minimal Read Permissions for group interns
resource "azurerm_role_definition" "minimal_reader" {
  name        = "Custom-Minimal-Infra-Reader"
  scope       = azurerm_resource_group.lab.id
  description = "Minimal read-only access to RG, VMs, and Storage metadata only"

  permissions {
    actions = [
      "Microsoft.Resources/subscriptions/resourceGroups/read",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Storage/storageAccounts/read"
    ]
    not_actions      = []
    data_actions     = []
    not_data_actions = []
  }

  assignable_scopes = [
    azurerm_resource_group.lab.id
  ]
}

# Custom Role Assignment
resource "azurerm_role_assignment" "interns_custom_reader" {
  scope              = azurerm_resource_group.lab.id
  role_definition_id = azurerm_role_definition.minimal_reader.role_definition_resource_id
  principal_id       = azuread_group.interns.object_id
}