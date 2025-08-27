#
# INFRASTRUCTURE: CLOUD WORKSTATION CLUSTER (Network, Subnet, Workstation Cluster)
#

resource "google_compute_network" "default" {
  provider                = google-beta
  name                    = var.cloud_workstation_cluster_network_name
  auto_create_subnetworks = false
  depends_on              = [time_sleep.wait_api_init]
}

resource "google_compute_subnetwork" "default" {
  provider                 = google-beta
  name                     = var.cloud_workstation_cluster_subnet_name
  ip_cidr_range            = var.cloud_workstation_cluster_subnet_iprange
  region                   = var.gcp_region
  network                  = google_compute_network.default.name
  private_ip_google_access = true
}

resource "google_workstations_workstation_cluster" "default" {
  provider               = google-beta
  workstation_cluster_id = var.cloud_workstation_cluster_id
  network                = google_compute_network.default.id
  subnetwork             = google_compute_subnetwork.default.id
  location               = var.gcp_region
}
