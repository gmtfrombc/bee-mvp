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

variable "supabase_url" {
  description = "Full base URL of the Supabase project (e.g. https://abcd.supabase.co). Used to derive project reference for migrations."
  type        = string
}