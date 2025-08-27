#
# CLOUD WORKSTATION INSTANCE
#
resource "google_workstations_workstation" "default" {
  provider = google-beta
  for_each = { for config in var.workstation_configs : config => config }

  workstation_id         = "${var.cloud_workstation_prefix}-${each.key}"
  workstation_config_id  = google_workstations_workstation_config.default[each.key].workstation_config_id
  workstation_cluster_id = google_workstations_workstation_cluster.default.workstation_cluster_id
  location               = var.gcp_region
}