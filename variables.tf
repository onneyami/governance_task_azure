variable "location" {
  type        = string
  default     = "westeurope"
  description = "Azure region for the deployed resources"
}

variable "rg_name" {
  type        = string
  default     = "rg-andrei"
  description = "Name of the target resource group"
}

variable "environment_tag" {
  type        = string
  default     = "Lab"
  description = "Default environment tag value"
}

variable "allowed_location" {
  type        = string
  default     = "westeurope" 
  description = "Azure region permitted by the subscription's Allowed locations policy"
}