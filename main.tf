# Target Resource Group
resource "azurerm_resource_group" "lab" {
  name     = var.rg_name
  location = var.location
  tags = {
    Environment = var.environment_tag
  }
}

# Test User in Entra ID for group interns
resource "azuread_user" "intern_test" {
  user_principal_name = "test.intern@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "Test Intern"
  mail_nickname       = "test.intern"
  password            = "TempP@ssw0rd2026!"
}

# Entra ID Security Group interns
resource "azuread_group" "interns" {
  display_name     = "interns"
  security_enabled = true
  description      = "Security group for interns with read-only access"
}

# Add User to Group
resource "azuread_group_member" "intern_member" {
  group_object_id  = azuread_group.interns.object_id
  member_object_id = azuread_user.intern_test.object_id
}