#
# SERVICE ACCOUNTS & IAM ROLES
#

# Reference to the project
data "google_project" "project" {
}

#
# Default compute Service Account roles
#
resource "google_project_iam_member" "compute_storage_access" {
  project    = data.google_project.project.project_id
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_api_init]
}

resource "google_project_iam_member" "compute_object_creator" {
  project    = data.google_project.project.project_id
  role       = "roles/storage.objectCreator"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_api_init]
}

resource "google_artifact_registry_repository_iam_member" "compute_artifact_registry_writer" {
  location   = var.gcp_region
  project    = var.gcp_project_id
  repository = var.artifactregistry_repository_name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    time_sleep.wait_api_init,
    google_artifact_registry_repository.cloud-workstation-images
  ]
}

resource "google_project_iam_member" "compute_log_writer" {
  project    = var.gcp_project_id
  role       = "roles/logging.logWriter"
  member     = "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  depends_on = [time_sleep.wait_api_init]
}

#
# Custom Cloud Workstations Service Account roles
#
resource "google_service_account" "cloud-workstation-sa" {
  provider     = google-beta
  account_id   = "cloud-workstation-vm-sa"
  display_name = "Cloud Workstation VM Service Account"
  depends_on   = [time_sleep.wait_api_init]
}


resource "google_artifact_registry_repository_iam_member" "cw-sa-ar-permissions" {
  provider   = google-beta
  project    = var.gcp_project_id
  location   = google_artifact_registry_repository.cloud-workstation-images.location
  repository = google_artifact_registry_repository.cloud-workstation-images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.cloud-workstation-sa.email}"
}

resource "google_project_iam_member" "cw-sa-storage-user" {
  project = var.gcp_project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.cloud-workstation-sa.email}"
}

#
# Cloud Build Service Account
#
resource "google_service_account" "cloudbuild_service_account" {
  account_id   = "cloudbuild-sa"
  display_name = "cloudbuild-sa"
  description  = "Cloud build service account"
  depends_on   = [time_sleep.wait_api_init]
}

resource "google_project_iam_member" "act_as" {
  project = var.gcp_project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_artifact_registry_repository_iam_member" "cloudbuild_artifactregistry_writer" {
  repository = google_artifact_registry_repository.cloud-workstation-images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

resource "google_project_iam_member" "cloudbuild_config_editor" {
  project = var.gcp_project_id
  role    = "roles/workstations.admin"
  member  = "serviceAccount:${google_service_account.cloudbuild_service_account.email}"
}

#
# IAM Bindings
# (add here the different service accounts writing logs)
#
resource "google_project_iam_binding" "log_writers" {
  project = var.gcp_project_id
  role    = "roles/logging.logWriter"
  members = [
    "serviceAccount:${google_service_account.cloud-workstation-sa.email}",
    "serviceAccount:${google_service_account.cloudbuild_service_account.email}",
    "serviceAccount:${data.google_project.project.number}-compute@developer.gserviceaccount.com"
  ]
  depends_on = [time_sleep.wait_api_init]
}

#
# IAM Workstation Admin+User Role
#
resource "google_project_iam_member" "workstations_admin" {
  project    = var.gcp_project_id
  role       = "roles/workstations.admin"
  member     = "user:${var.admin_email}"
  depends_on = [time_sleep.wait_api_init]
}

resource "google_workstations_workstation_iam_member" "workstations_user" {
  provider               = google-beta
  for_each               = { for config in var.workstation_configs : config => config }
  project                = var.gcp_project_id
  location               = var.gcp_region
  workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
  workstation_config_id  = google_workstations_workstation_config.default[each.key].workstation_config_id
  workstation_id         = google_workstations_workstation.default[each.key].workstation_id
  role                   = "roles/workstations.user"
  member                 = "user:${var.admin_email}"
}

