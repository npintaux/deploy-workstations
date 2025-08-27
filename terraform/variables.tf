#
# GCP ENVIRONMENT VARIABLES
#
variable "gcp_project_id" {
  description = "The GCP project ID"
  type        = string
  # default = [your-default-value]
}

variable "gcp_region" {
  description = "The GCP region"
  type        = string
  # default = [your-default-value]
}

variable "gcp_zone" {
  description = "The GCP zone"
  type        = string
  # default = [your-default-value]
}

#
# CLOUD WORKSTATION CLUSTER VARIABLES
#
variable "cloud_workstation_cluster_id" {
  description = "The ID of the Cloud Workstation cluster"
  type        = string
  default     = "cloud-workstation-cluster"
}

variable "cloud_workstation_cluster_network_name" {
  description = "The name of the Cloud Workstation cluster network"
  type        = string
  default     = "workstation-cluster-network"
}

variable "cloud_workstation_cluster_subnet_name" {
  description = "The name of the Cloud Workstation cluster subnet"
  type        = string
  default     = "workstation-cluster-subnet"
}

variable "cloud_workstation_cluster_subnet_iprange" {
  description = "The IP range of the Cloud Workstation cluster subnet"
  type        = string
  default     = "10.0.0.0/24"
}


#
# CLOUD WORKSTATION CONFIG VARIABLES
#

variable "cloud_workstation_machine_type" {
  description = "The machine type of the Cloud Workstation config"
  type        = string
  default     = "e2-standard-4"
}

# Define a list of workstation configuration names
variable "workstation_configs" {
  type    = list(string)
  default = ["default"] # Replace with your actual configuration names
}

# Define the size of the pool when deployed
variable "workstation_pool_size" {
  type    = string
  default = "0"
}

#
# CLOUD WORKSTATION IMAGE
#
variable "custom-image-name" {
  description = "The name of the folder where the Dockerfile resides"
  type        = string
  default     = "default"
}

variable "custom-image-tag" {
  description = "The tag of the Docker image"
  type        = string
  default     = "first-build"
}

#
# CLOUD WORKSTATION INSTANCE
#
variable "cloud_workstation_prefix" {
  description = "The prefix for the Cloud Workstation instances"
  type        = string
  default     = "ws"
}

#
# ARTIFACT REGISTRY REPOSITORY
#
variable "artifactregistry_repository_name" {
  description = "The ID of the Artifact Registry repository"
  type        = string
  default     = "cloud-workstation-images"
}

#
# User variables
#
variable "admin_email" {
  description = "The admin email"
  type        = string
  # no default value as this is a mandatory variable
}