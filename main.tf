# Reference the existing Resource Group
data "azurerm_resource_group" "lab" {
  name = var.rg_name
}

# Test User in Entra ID for group interns
#resource "azuread_user" "intern_test" {
#  user_principal_name = "test.intern@${data.azuread_domains.default.domains[0].domain_name}"
#  display_name        = "Test Intern"
#  mail_nickname       = "test.intern"
#  password            = "TempP@ssw0rd2026!"
#}

# Entra ID Security Group interns
#resource "azuread_group" "interns" {
#  display_name     = "interns"
#  security_enabled = true
#  description      = "Security group for interns with read-only access"
#}

# Add User to Group
#resource "azuread_group_member" "intern_member" {
#  group_object_id  = azuread_group.interns.object_id
#  member_object_id = azuread_user.intern_test.object_id
#}

# Managed Identity acting as the test principal (no Entra ID admin rights required)
resource "azurerm_user_assigned_identity" "intern_principal" {
  name                = "id-intern-lab"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = var.allowed_location
}