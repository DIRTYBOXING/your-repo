variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "australia-southeast1"
}

variable "assets_bucket" {
  description = "GCS bucket name for poster and media assets"
  type        = string
}

variable "ops_email" {
  description = "Operations team email for monitoring alerts"
  type        = string
  default     = "ops@datafightcentral.com"
}

variable "billing_account_id" {
  description = "Google Cloud billing account ID for budget alerts"
  type        = string
  default     = "" # Set via terraform.tfvars or CLI
}

variable "monthly_budget_usd" {
  description = "Monthly budget cap in USD — alerts fire at 50%, 80%, 100%"
  type        = number
  default     = 200
}
