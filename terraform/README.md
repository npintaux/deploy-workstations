# Deploying your Cloud Workstation using Terraform
The following paragraphs provide easy instruction to deploy your cloud workstation using Terraform in a brand new project. Special care has been brought to enable all required APIs, and to set up the correct IAM permissions to make sure that the Cloud Workstation can be used as is.

# Key Features
*   **Multiple Workstation Configurations:** The Terraform setup now supports deploying multiple, distinct Cloud Workstation configurations, as defined in the `workstation_configs` variable. This allows for different development environments (e.g., `default`, `minimal`, `minimal-with-vscode`).
*   **Automated Image Builds:** A new CI/CD pipeline is established using Cloud Build and GitLab. It automatically builds custom workstation images when changes are pushed to the `main` branch of your GitLab repository.
*   **GitLab Integration:** The configuration integrates with GitLab to trigger these image builds, connecting to your repository via a Cloud Build connection.
*   **Secret Management:** GitLab personal access tokens (PATs) are securely stored in Google Secret Manager. An initialization script can be provided in the configuration (see 'default' configuration folder) to allow the user to retrieve these tokens.
*   **Dynamic Configuration:** The setup is highly configurable through an extensive set of variables in `variables.tf`, allowing you to customize everything from network settings to image tags.

# Prerequisites
To test your first deployment, you will first need a project with billing enabled. Then you will need to create a Terraform variable file, with the extension `.tfvars` or `tfvars.json`, with the following variables:

**[Mandatory Variables]**
*   `gcp_project_id`: The ID of the Google Cloud project.
*   `gcp_region`: The region for deployment.
*   `admin_email`: The email address for the administrator.
*   `gitlab_repo_url`: The URL of the GitLab repository containing your custom image configurations.
*   `gitlab_cloudbuild_pat`: Your GitLab personal access token for Cloud Build integration.
*   `gitlab_user_pat`: Your GitLab personal access token for user-related actions.

**[Optional Variables]**
A comprehensive list of optional variables is available in the `variables.tf` file, allowing you to customize aspects such as:
*   Workstation cluster and network settings
*   Machine types and pool sizes
*   Artifact Registry repository names
*   Custom image tags

## Resources being created
The following resources are created:
- APIs enabled: `serviceusage.googleapis.com`, `cloudresourcemanager.googleapis.com`, `artifactregistry.googleapis.com`, `iam.googleapis.com`, `compute.googleapis.com` and `workstations.googleapis.com` (listed in apis.tf). `serviceusage.googleapis.com` and `cloudresourcemanager.googleapis.com` are enabled first using a `gcloud` command to avoid a terraform interlock. A 60-second delay is then implemented to allow for the API enablements to propagate through the system.
- IAM role: a service account called `cloud-workstation-vm-sa` is created and gets the role of `roles/artifactregistry.reader`. This role is used by the Cloud Workstation VM to pull the cloud workstation image from Artifact Registry. Please note that this role is assigned using the `google_artifact_registry_repository_iam_member` resource (the project-level resource does not seem to work properly).
- VPC and subnet: to host the Cloud Workstation cluster.
- Cloud Workstation cluster
- Cloud Workstation configuration
- Cloud Workstation
- Artifact Registry Docker repository. Its default name is `cloud-workstation-images`.
- A Cloud Build trigger for each configuration, that automatically builds a new custom image every time a change is pushed to the `main` branch of your GitLab repository. The trigger is setup so that it is run only when the files corresponding to this configuration are modified.

## Deploying the Cloud Workstation
As with an Terraform deployment, the sequence of steps to deploy an infrastructure is:
```
terraform init
terraform plan
terraform apply
```
The full deployment of the cluster, configuration and cloud workstation takes approximately 20 minutes.
