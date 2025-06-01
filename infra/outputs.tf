# Infrastructure Outputs

output "supabase_secrets" {
  description = "Names of the created Supabase secrets in Secret Manager"
  value = {
    url_secret = google_secret_manager_secret.supabase_url.secret_id
    key_secret = google_secret_manager_secret.supabase_service_key.secret_id
  }
}

output "enabled_apis" {
  description = "List of enabled GCP APIs"
  value = [
    google_project_service.cloud_run.service,
    google_project_service.cloud_build.service,
    google_project_service.vertex_ai.service,
    google_project_service.cloud_scheduler.service,
    google_project_service.monitoring.service,
    google_project_service.logging.service
  ]
} 