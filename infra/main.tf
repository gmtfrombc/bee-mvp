terraform {
  required_version = ">= 1.5"
  required_providers {
    google   = { source = "hashicorp/google", version = "~> 5.0" }
    supabase = { source = "supabase/supabase", version = "~> 1.0" }
  }
}

provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
}

provider "supabase" {
  # will read SUPABASE_ACCESS_TOKEN env var in CI
}

# Enable required APIs
resource "google_project_service" "cloud_run" {
  service = "run.googleapis.com"
}

resource "google_project_service" "cloud_build" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "vertex_ai" {
  service = "aiplatform.googleapis.com"
}

resource "google_project_service" "cloud_scheduler" {
  service = "cloudscheduler.googleapis.com"
}

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}

resource "google_project_service" "secret_manager" {
  service = "secretmanager.googleapis.com"
}

# Secret Manager secrets for Supabase configuration
resource "google_secret_manager_secret" "supabase_url" {
  secret_id = "supabase-url"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

resource "google_secret_manager_secret" "supabase_service_key" {
  secret_id = "supabase-service-key"

  replication {
    auto {}
  }

  depends_on = [google_project_service.secret_manager]
}

# ---------------------------------------------------------------------------
# Supabase migration for Auth Profiles (M1.6.1)
# ---------------------------------------------------------------------------

data "supabase_project" "current" {}

resource "supabase_migration" "auth_profiles" {
  project_ref   = data.supabase_project.current.id
  version       = var.supabase_migration_tag
  migration_sql = file("${path.module}/../supabase/migrations/20240722120000_v1.6.1_profiles.sql")
}