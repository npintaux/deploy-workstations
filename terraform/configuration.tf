#
# CONFIGURATION
#
resource "google_workstations_workstation_config" "default" {
  provider = google-beta
  for_each = { for config in var.workstation_configs : config => config }

  workstation_config_id  = "${each.key}-config"
  workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
  location               = var.gcp_region
  idle_timeout           = "1800s"

  host {
    gce_instance {
      machine_type                = var.cloud_workstation_machine_type
      boot_disk_size_gb           = 35
      disable_public_ip_addresses = false
      pool_size                   = var.workstation_pool_size
      service_account             = google_service_account.cloud-workstation-sa.email
      shielded_instance_config {
        enable_secure_boot          = true
        enable_vtpm                 = true
        enable_integrity_monitoring = true
      }
    }
  }
  persistent_directories {
    mount_path = "/home"
    gce_pd {
      disk_type      = "pd-ssd"
      size_gb        = 100
      reclaim_policy = "DELETE"
    }
  }
  container {
    image = "${var.gcp_region}-docker.pkg.dev/${var.gcp_project_id}/${var.artifactregistry_repository_name}/${each.key}:${var.custom-image-tag}"
  }
  depends_on = [
    google_artifact_registry_repository.cloud-workstation-images,
    null_resource.trigger_initial_build
  ]
}