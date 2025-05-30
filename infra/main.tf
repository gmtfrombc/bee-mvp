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

# Cloud Run service for Today Feed Content Generator
resource "google_cloud_run_service" "today_feed_generator" {
  name     = "today-feed-generator"
  location = var.gcp_region

  template {
    spec {
      containers {
        image = "gcr.io/${var.gcp_project}/today-feed-generator:latest"
        
        ports {
          container_port = 8080
        }

        env {
          name  = "GCP_PROJECT_ID"
          value = var.gcp_project
        }

        env {
          name  = "VERTEX_AI_LOCATION"
          value = var.gcp_region
        }

        env {
          name = "SUPABASE_URL"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.supabase_url.secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "SUPABASE_SERVICE_ROLE_KEY"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.supabase_service_key.secret_id
              key  = "latest"
            }
          }
        }

        resources {
          limits = {
            cpu    = "1"
            memory = "1Gi"
          }
        }
      }

      container_concurrency = 100
      timeout_seconds      = 300
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "autoscaling.knative.dev/minScale" = "0"
        "run.googleapis.com/cpu-throttling" = "false"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.cloud_run]
}

# Allow unauthenticated access to the Cloud Run service
resource "google_cloud_run_service_iam_member" "today_feed_generator_public" {
  service  = google_cloud_run_service.today_feed_generator.name
  location = google_cloud_run_service.today_feed_generator.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Secret Manager secrets for Supabase configuration
resource "google_secret_manager_secret" "supabase_url" {
  secret_id = "supabase-url"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "supabase_service_key" {
  secret_id = "supabase-service-key"

  replication {
    automatic = true
  }
}

# Cloud Scheduler job for daily content generation
resource "google_cloud_scheduler_job" "daily_content_generation" {
  name     = "daily-content-generation"
  region   = var.gcp_region
  schedule = "0 3 * * *"
  time_zone = "UTC"

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.today_feed_generator.status[0].url}/generate"

    headers = {
      "Content-Type" = "application/json"
    }

    body = base64encode("{}")
  }

  depends_on = [
    google_project_service.cloud_scheduler,
    google_cloud_run_service.today_feed_generator
  ]
}