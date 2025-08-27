# # #
# # # Cloud Build connection to GitLab + trigger.
# # # The custom image is generated using a first local-exec Cloud Build call.
# # #


# Triggers an initial build once the Cloud Build trigger is created.check.
# Although null resources are not good practice, this type of trigger can be
# justified given its one-time nature.
resource "null_resource" "trigger_initial_build" {
  for_each = { for config in var.workstation_configs : config => config }
  provisioner "local-exec" {
    command = <<EOT
      cd ../custom-images/${each.value} && \
      gcloud beta builds submit \
        --project=${var.gcp_project_id} \
        --region=${var.gcp_region} \
        --config=../cloudbuild.yaml \
        --substitutions=_REPOSITORY_NAME='${var.artifactregistry_repository_name}',_IMAGE_NAME='${each.value}',_BUILD_CONTEXT='.',_UNIQUE_TAG='first-build'
      EOT
  }

  depends_on = [
    time_sleep.wait_api_init,
    google_artifact_registry_repository_iam_member.compute_artifact_registry_writer,
    google_project_iam_member.compute_log_writer
  ]
}