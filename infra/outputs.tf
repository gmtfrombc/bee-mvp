# Today Feed Content Generator Service Outputs

output "today_feed_generator_url" {
  description = "URL of the Today Feed Content Generator Cloud Run service"
  value       = google_cloud_run_service.today_feed_generator.status[0].url
}

output "today_feed_generator_name" {
  description = "Name of the Today Feed Content Generator service"
  value       = google_cloud_run_service.today_feed_generator.name
}

output "daily_content_generation_job_name" {
  description = "Name of the daily content generation Cloud Scheduler job"
  value       = google_cloud_scheduler_job.daily_content_generation.name
}

output "supabase_secrets" {
  description = "Names of the created Supabase secrets in Secret Manager"
  value = {
    url_secret = google_secret_manager_secret.supabase_url.secret_id
    key_secret = google_secret_manager_secret.supabase_service_key.secret_id
  }
}

output "enabled_apis" {
  description = "List of enabled GCP APIs for the Today Feed service"
  value = [
    google_project_service.cloud_run.service,
    google_project_service.cloud_build.service,
    google_project_service.vertex_ai.service,
    google_project_service.cloud_scheduler.service
  ]
} 