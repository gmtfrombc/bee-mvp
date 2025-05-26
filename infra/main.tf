terraform {
  required_version = ">= 1.5"
  required_providers {
    google   = { source = "hashicorp/google", version = "~> 5.0" }
    supabase = { source = "Supabase/supabase", version = "~> 0.8" }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "supabase" {
  # will read SUPABASE_ACCESS_TOKEN env var in CI
}

# (no resources yet – just a placeholder)