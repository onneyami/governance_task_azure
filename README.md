
# Azure Governance, RBAC & Policy Lab (Terraform)

This repository provisions an Azure Governance and Identity lab using Terraform (`azurerm` and `azuread` providers). It automates Entra ID user/group provisioning, scopes built-in and custom RBAC roles to an existing Resource Group, enforces tag inheritance via Azure Policy (`Modify`), and executes automated remediation on non-compliant resources.

---

## Architecture & Repository Structure

```text
governance_task_azure/
├── providers.tf   # Terraform version constraints, azurerm & azuread providers, tenant/subscription data sources
├── variables.tf   # Input variables (existing Resource Group name, allowed Azure region)
├── main.tf        # Existing RG data source, Entra ID test user, 'interns' security group, and membership
├── rbac.tf        # Built-in Reader assignment, Custom Minimal Reader role definition, and assignment
├── policy.tf      # Built-in Tag Inheritance policy assignment, Managed Identity RBAC, test SA, and remediation
├── outputs.tf     # Resource Group ID and Entra ID group Object ID outputs
└── README.md      # Project documentation, verification steps, design review, and Break/Fix guide
```

---

## Prerequisites

1. **Tools Installed:**

   * [Terraform](https://developer.hashicorp.com/terraform/downloads) `>= 1.5.0`
   * [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (`az`) authenticated via `az login` or Service Principal environment variables.
2. **Existing Resource Group:**

   * A pre-existing Resource Group (default: `rg-andrei`) must exist in your subscription.
   * Ensure the `Environment` tag is set on `rg-andrei` (e.g., `Environment = Lab`) so the tag inheritance policy has a value to copy during remediation.
3. **Required Permissions:**

   * **Azure Subscription / RG RBAC:** `Contributor` plus `Role Based Access Control Administrator` (or `User Access Administrator`) and `Resource Policy Contributor`.
   * **Microsoft Entra ID:**
     * *Interactive User (`az login`):* `User Administrator` and `Groups Administrator` directory roles.
     * *Service Principal (SPN):* Microsoft Graph Application permissions `User.ReadWrite.All` and `Group.ReadWrite.All` with **Admin Consent** granted.
4. **Subscription Location Restrictions:**

   * If your subscription enforces an `Allowed locations` policy, verify permitted regions before applying:

```bash
az policy assignment list --query "[?contains(displayName, 'Allowed locations')].parameters.listOfAllowedLocations.value"
```

---

## Inputs & Outputs

### Variables (`variables.tf`)

| Name                 | Description                                                                          | Type       | Default         |
| :------------------- | :----------------------------------------------------------------------------------- | :--------- | :-------------- |
| `rg_name`          | Name of the existing target Resource Group                                           | `string` | `"rg-andrei"` |
| `allowed_location` | Azure region permitted by subscription policy for new resources and Managed Identity | `string` | `"eastus"`    |

### Outputs (`outputs.tf`)

| Name                  | Description                                              |
| :-------------------- | :------------------------------------------------------- |
| `resource_group_id` | Resource ID of the target Resource Group (`rg-andrei`) |
| `intern_group_id`   | Entra ID Object ID of the `interns` security group     |

---

## Deployment & Verification

### 1. Deploy Infrastructure

> **Note:** Azure Storage Account names must be globally unique. If `stnoncomplab2026` is already taken, update `name` in `policy.tf` before running `apply`.

```bash
terraform init
terraform validate
terraform plan -var="allowed_location=<your-allowed-region>"
terraform apply -var="allowed_location=<your-allowed-region>"
```

### 2. Verify RBAC Assignments

Confirm that both the built-in `Reader` role and `Custom-Minimal-Infra-Reader` role are scoped strictly to `rg-andrei`:

```bash
az role assignment list \
  --resource-group rg-andrei \
  --assignee $(terraform output -raw intern_group_id) \
  --query "[].{Role:roleDefinitionName, Scope:scope}" -o table
```

### 3. Verify Policy Compliance & Remediation

Azure Policy background evaluations run every ~30 minutes. Trigger an on-demand compliance scan and inspect the storage account's tags:

```bash
# Trigger immediate policy evaluation on the Resource Group
az policy state trigger-scan --resource-group rg-andrei

# Check compliance state for resources in rg-andrei
az policy state list \
  --resource-group rg-andrei \
  --query "[].{Resource:resourceId, Policy:policyAssignmentName, State:complianceState}" -o table

# Verify the 'Environment' tag was inherited onto the storage account
az storage account show \
  --name stnoncomplab2026 \
  --resource-group rg-andrei \
  --query "tags"
```

---

## Custom Role Design Review Checklist

The custom role `Custom-Minimal-Infra-Reader` in `rbac.tf` follows these security design principles:

* **Principle of Least Privilege (PoLP):** Avoids broad wildcards (`*` or `Microsoft.Storage/*`, which implicitly grants `listKeys/action` and exposes storage access keys). Explicitly lists only `/read` actions for Resource Groups, Virtual Machines, and Storage Accounts.
* **Control Plane vs. Data Plane Separation:** `data_actions` and `not_data_actions` are left empty (`[]`), ensuring interns can inspect resource metadata in the Azure Portal/CLI without reading blob contents, queues, or VM disks.
* **Restricted `assignable_scopes`:** Scoped solely to `data.azurerm_resource_group.lab.id` rather than the subscription or Root Management Group, preventing accidental broad assignment.
* **Explicit Exclusions (`not_actions`):** When building roles from broader read templates (e.g., `*/read`), always exclude sensitive read endpoints such as `Microsoft.Authorization/*/read` or credential-listing endpoints.

---

## Break/Fix Troubleshooting Guide

| Scenario                                                                        | Symptoms / Diagnosis                                                                                                                                                             | Resolution                                                                                                                                                                                                                                                                                                               |
| :------------------------------------------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **1. Role assignment applied to Subscription instead of RG**              | `interns` group sees all Resource Groups across the subscription. `terraform state show azurerm_role_assignment.interns_reader` shows `scope = "/subscriptions/<sub-id>"`. | Update `scope` in `rbac.tf` to `data.azurerm_resource_group.lab.id`. Because `scope` forces replacement, `terraform apply` destroys the subscription-level assignment and recreates it on the RG.                                                                                                              |
| **2. Policy assignment exists, but resource is excluded or out of scope** | Non-compliant resources appear `Compliant` or are missing from compliance reports.                                                                                             | 1. Verify `resource_group_id` in `azurerm_resource_group_policy_assignment`.2. Check `not_scopes` on the assignment and remove the target RG/resource.3. Check for and remove any `azurerm_resource_group_policy_exemption` resources.4. Confirm `enforce = true` (`Default` enforcement mode).              |
| **3. Service Principal / User lacks required permissions**                | `terraform apply` fails with `AuthorizationFailed` (Azure RBAC) or `Authorization_RequestDenied` (Entra ID).                                                               | 1. **Azure RBAC:** Assign `Role Based Access Control Administrator` and `Resource Policy Contributor` on the target scope.2. **Entra ID:** Assign `User Administrator` + `Groups Administrator` (or `User.ReadWrite.All` + `Group.ReadWrite.All` Graph permissions with admin consent for SPNs). |
| **4. `RequestDisallowedByPolicy` (`Allowed locations`)**              | Resource creation fails with HTTP 403 citing an `Allowed locations` policy.                                                                                                    | Pass a permitted region via `-var="allowed_location=<region>"` so resources deploy to an allowed location even if `rg-andrei` resides in a restricted region.                                                                                                                                                        |

---

## Cleanup

To remove all Terraform-managed resources (roles, policy assignments, remediation tasks, storage account, Entra ID user, and `interns` group):

```bash
terraform destroy -var="allowed_location=<your-allowed-region>"
```

*(Because `rg-andrei` is referenced as a `data` source, `terraform destroy` will leave the existing Resource Group intact.)*
