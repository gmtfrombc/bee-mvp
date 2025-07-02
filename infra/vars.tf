variable "gcp_project" {
  type = string
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "supabase_migration_tag" {
  description = "Tag of the latest database migration applied via Terraform"
  type        = string
}