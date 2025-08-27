#
# The following resources enable the APIs necessary for a generic Cloud Workstations deployment
# A sleep duration of a 5 minutes is proposed to allow for all APIs to be propagated.
#

locals {
  # Define all the APIs you want to enable in a list
  apis_to_enable = [
    "serviceusage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "workstations.googleapis.com",
    "artifactregistry.googleapis.com",
    "secretmanager.googleapis.com",
    "storage.googleapis.com",
    "logging.googleapis.com",
    "cloudbuild.googleapis.com",
  ]
}

# Use for_each to create a resource for each API in the list
resource "google_project_service" "enable_apis" {
  for_each = toset(local.apis_to_enable)

  project = var.gcp_project_id
  service = each.key

  # Prevents Terraform from disabling the API when the resource is destroyed
  disable_on_destroy = false
}

#
# Wait for the APIs to be enabled globally - this is necessary for specific APIs such as Cloud Build.
# 
resource "time_sleep" "wait_api_init" {
  create_duration = "300s"

  depends_on = [google_project_service.enable_apis]
}