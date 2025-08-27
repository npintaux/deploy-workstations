resource "google_artifact_registry_repository" "cloud-workstation-images" {
  provider      = google-beta
  project       = var.gcp_project_id
  location      = var.gcp_region
  repository_id = var.artifactregistry_repository_name
  description   = "Repository for custom Cloud Workstation images"
  format        = "Docker"
  depends_on    = [time_sleep.wait_api_init]
}
