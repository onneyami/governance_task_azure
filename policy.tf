# Built-in Policy: Inherit tag from resource group
data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

# Policy Assignment with System Assigned Managed Identity
resource "azurerm_resource_group_policy_assignment" "inherit_env_tag" {
  name                 = "inherit-env-tag-from-rg"
  resource_group_id    = data.azurerm_resource_group.lab.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  location             = data.azurerm_resource_group.lab.location

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = {
      value = "Environment"
    }
  })
}

# Grant the Policy's Managed Identity permission to modify tags
resource "azurerm_role_assignment" "policy_mi_tag_contributor" {
  scope                = data.azurerm_resource_group.lab.id
  role_definition_name = "Tag Contributor"
  principal_id         = azurerm_resource_group_policy_assignment.inherit_env_tag.identity[0].principal_id
}

# Test resource intentionally missing the 'Environment' tag to trigger non-compliance
resource "azurerm_storage_account" "non_compliant_sa" {
  name                     = "stnoncomplab2026"
  resource_group_name      = data.azurerm_resource_group.lab.name
  location                 = var.allowed_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Remediation task to automatically fix existing non-compliant resources
resource "azurerm_resource_group_policy_remediation" "remediate_env_tag" {
  name                 = "remediate-missing-env-tag"
  resource_group_id    = data.azurerm_resource_group.lab.id
  policy_assignment_id = azurerm_resource_group_policy_assignment.inherit_env_tag.id

  depends_on = [
    azurerm_role_assignment.policy_mi_tag_contributor,
    azurerm_storage_account.non_compliant_sa
  ]
}