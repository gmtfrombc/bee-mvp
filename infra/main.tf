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
      timeout_seconds       = 300
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = "10"
        "autoscaling.knative.dev/minScale"  = "0"
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
    auto {}
  }
}

resource "google_secret_manager_secret" "supabase_service_key" {
  secret_id = "supabase-service-key"

  replication {
    auto {}
  }
}

# Cloud Scheduler job for daily content generation
resource "google_cloud_scheduler_job" "daily_content_generation" {
  name        = "daily-content-generation"
  region      = var.gcp_region
  schedule    = "0 3 * * *" # 3 AM UTC daily
  time_zone   = "UTC"
  description = "Automated daily content generation for Today Feed at 3 AM UTC"

  # Add retry configuration for failed attempts
  retry_config {
    retry_count          = 3
    max_retry_duration   = "600s" # 10 minutes max for retries
    min_backoff_duration = "30s"
    max_backoff_duration = "300s" # 5 minutes max backoff
    max_doublings        = 3
  }

  http_target {
    http_method = "POST"
    uri         = "${google_cloud_run_service.today_feed_generator.status[0].url}/generate"

    headers = {
      "Content-Type" = "application/json"
      "User-Agent"   = "Google-Cloud-Scheduler"
    }

    # Enhanced request body with scheduling metadata
    body = base64encode(jsonencode({
      scheduled    = true
      source       = "cloud-scheduler"
      timezone     = "UTC"
      trigger_time = "3AM"
    }))

    # Add authentication for secure endpoint access
    oauth_token {
      service_account_email = google_service_account.scheduler_service_account.email
    }
  }

  depends_on = [
    google_project_service.cloud_scheduler,
    google_cloud_run_service.today_feed_generator,
    google_service_account.scheduler_service_account
  ]
}

# Service account for Cloud Scheduler authentication
resource "google_service_account" "scheduler_service_account" {
  account_id   = "scheduler-service-account"
  display_name = "Cloud Scheduler Service Account"
  description  = "Service account for Cloud Scheduler to invoke Today Feed content generation"
}

# IAM binding to allow scheduler service account to invoke Cloud Run
resource "google_cloud_run_service_iam_member" "scheduler_invoker" {
  service  = google_cloud_run_service.today_feed_generator.name
  location = google_cloud_run_service.today_feed_generator.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_service_account.email}"
}

# Cloud Monitoring alerting policy for failed content generation
resource "google_monitoring_alert_policy" "content_generation_failure" {
  display_name = "Today Feed Content Generation Failure"
  combiner     = "OR"

  documentation {
    content = "Alert when daily content generation fails multiple times"
  }

  conditions {
    display_name = "Cloud Scheduler Job Failure"

    condition_threshold {
      filter = "resource.type=\"cloud_scheduler_job\" AND resource.labels.job_id=\"daily-content-generation\" AND metric.type=\"cloudscheduler.googleapis.com/job/num_failed_runs\""

      comparison      = "COMPARISON_GT"
      threshold_value = 1 # Alert after more than 1 failure
      duration        = "60s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  # Notification channels would be configured separately
  notification_channels = []

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  depends_on = [
    google_project_service.monitoring,
    google_cloud_scheduler_job.daily_content_generation
  ]
}