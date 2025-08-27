# Deploy Cloud Workstations with Terraform

This project provides Terraform scripts to deploy Google Cloud Workstations.

## Overview

The Terraform scripts in this project will:

*   Enable the necessary Google Cloud APIs.
*   Create a VPC network and subnetwork for the Cloud Workstation cluster.
*   Create a Cloud Workstation cluster.
*   Create an Artifact Registry repository for custom workstation images.
*   Build a custom workstation image using Cloud Build from a Dockerfile.
*   Create a Cloud Workstation configuration.
*   Create a Cloud Workstation instance.
*   Set up the necessary IAM service accounts and permissions.

## Prerequisites

Before you begin, ensure you have the following:

*   [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) installed and configured.
*   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed.
*   Authenticated with Google Cloud with Application Default Credentials:
    ```bash
    gcloud auth application-default login
    ```

## Deployment

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd deploy-workstations/terraform
    ```

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

3.  **Create a `terraform.tfvars` file:**

    Create a file named `terraform.tfvars` and add the following variables:

    ```hcl
    gcp_project_id = "your-gcp-project-id"
    gcp_region     = "your-gcp-region"
    gcp_zone       = "your-gcp-zone"
    admin_email    = "your-email@example.com"
    ```

4.  **Review the deployment plan:**
    ```bash
    terraform plan
    ```

5.  **Apply the Terraform configuration:**
    ```bash
    terraform apply
    ```

    This command will provision all the necessary resources. The initial Cloud Build to create the custom image will be triggered automatically.

## Inputs

The following input variables are defined in `variables.tf`:

| Name                                     | Description                                          | Type        | Default                       |
| ---------------------------------------- | ---------------------------------------------------- | ----------- | ----------------------------- |
| `gcp_project_id`                         | The GCP project ID.                                  | `string`    | n/a                           |
| `gcp_region`                             | The GCP region.                                      | `string`    | n/a                           |
| `gcp_zone`                               | The GCP zone.                                        | `string`    | n/a                           |
| `admin_email`                            | The admin email.                                     | `string`    | n/a                           |
| `cloud_workstation_cluster_id`           | The ID of the Cloud Workstation cluster.             | `string`    | "cloud-workstation-cluster"   |
| `cloud_workstation_cluster_network_name` | The name of the Cloud Workstation cluster network.   | `string`    | "workstation-cluster-network" |
| `cloud_workstation_cluster_subnet_name`  | The name of the Cloud Workstation cluster subnet.    | `string`    | "workstation-cluster-subnet"  |
| `cloud_workstation_cluster_subnet_iprange` | The IP range of the Cloud Workstation cluster subnet.| `string`    | "10.0.0.0/24"                 |
| `cloud_workstation_machine_type`         | The machine type of the Cloud Workstation config.    | `string`    | "e2-standard-4"               |
| `workstation_configs`                    | A list of workstation configuration names.           | `list(string)` | `["default"]`                 |
| `workstation_pool_size`                  | The size of the pool when deployed.                  | `string`    | "0"                           |
| `custom-image-name`                      | The name of the folder where the Dockerfile resides. | `string`    | "default"                     |
| `custom-image-tag`                       | The tag of the Docker image.                         | `string`    | "first-build"                 |
| `cloud_workstation_prefix`               | The prefix for the Cloud Workstation instances.      | `string`    | "ws"                          |
| `artifactregistry_repository_name`       | The ID of the Artifact Registry repository.          | `string`    | "cloud-workstation-images"    |

## Outputs

The following outputs are defined in `workstation.tf`:

| Name                               | Description                                            |
| ---------------------------------- | ------------------------------------------------------ |
| `workstation_uris`                 | The URIs of the created Cloud Workstation instances.   |
| `workstation_cluster_name`         | The name of the Cloud Workstation cluster.             |
| `workstation_config_name`          | The name of the Cloud Workstation configuration.       |
| `workstation_names`                | The names of the Cloud Workstation instances.          |
| `workstation_service_account_email`| The email of the Cloud Workstation service account.    |
| `cloudbuild_service_account_email` | The email of the Cloud Build service account.          |
| `artifact_registry_repository_name`| The name of the Artifact Registry repository.          |
| ...                                | (and many other outputs related to the created resources)|

## Cleanup

To destroy all the resources created by this Terraform configuration, run the following command:

```bash
terraform destroy
```