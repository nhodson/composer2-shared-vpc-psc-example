#####################################
# Composer service project IAM
#####################################

# (Once per project) Grant required permissions to Cloud Composer service account
# https://cloud.google.com/composer/docs/composer-2/create-environments#grant-permissions
resource "google_project_iam_member" "composer_service_agent" {
  project = module.composer_project.project_id
  role    = "roles/composer.ServiceAgentV2Ext"
  member  = "serviceAccount:service-${module.composer_project.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"
}

# Assign roles to user-managed service account
# https://cloud.google.com/composer/docs/composer-2/access-control#service-account
resource "google_project_iam_member" "composer_worker" {
  project = module.composer_project.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${module.composer_project.service_account_email}"
}

#####################################
# Shared VPC host project IAM
#####################################

# Permissions for Google APIs service account
# https://cloud.google.com/composer/docs/composer-2/configure-shared-vpc#edit_permissions_for_the_google_apis_service_account
resource "google_project_iam_member" "host_composer_services_network_user" {
  project = var.host_project_id
  role    = "roles/compute.networkUser"
  member  = "serviceAccount:${module.composer_project.project_number}@cloudservices.gserviceaccount.com"
}

# Permissions for GKE service account on subnet
# https://cloud.google.com/composer/docs/composer-2/configure-shared-vpc#edit_permissions_for_service_accounts
resource "google_compute_subnetwork_iam_member" "composer_gke" {
  project    = var.host_project_id
  subnetwork = var.svpc_subnet
  role       = "roles/compute.networkUser"
  member     = "serviceAccount:service-${module.composer_project.project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# Permissions for GKE service account on host agent
# https://cloud.google.com/composer/docs/composer-2/configure-shared-vpc#edit_permissions_for_the_service_account_of_the_service_project
resource "google_project_iam_member" "host_composer_gke_service_agent" {
  project = var.host_project_id
  role    = "roles/container.hostServiceAgentUser"
  member  = "serviceAccount:service-${module.composer_project.project_number}@container-engine-robot.iam.gserviceaccount.com"
}

# Permissions for Composer Agent service account
# https://cloud.google.com/composer/docs/composer-2/configure-shared-vpc#edit_permissions_for_the_composer_agent_service_account
resource "google_project_service_identity" "host_composer" {
  provider = google-beta

  project = var.host_project_id
  service = "composer.googleapis.com"
}

resource "google_project_iam_member" "host_composer_svpc_agent" {
  project = var.host_project_id
  role    = "roles/composer.sharedVpcAgent"
  member  = "serviceAccount:service-${module.composer_project.project_number}@cloudcomposer-accounts.iam.gserviceaccount.com"

  depends_on = [
    google_project_service_identity.host_composer
  ]
}


#####################################
# Composer Environment Creation
#####################################
resource "google_composer_environment" "svpc_test" {
  provider = google-beta
  project  = module.composer_project.project_id
  name     = "svpc-test-composer2-psc"
  region   = "us-central1"

  config {
    software_config {
      image_version = "composer-2.0.5-airflow-2.2.3"
    }

    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      network    = "projects/${var.host_project_id}/global/networks/${var.svpc_network}"
      subnetwork = var.svpc_subnet

      service_account = module.composer_project.service_account_email

      ip_allocation_policy {
        cluster_secondary_range_name  = var.pods_range_name
        services_secondary_range_name = var.svcs_range_name
      }
    }

    private_environment_config {
      enable_private_endpoint              = true
      cloud_composer_connection_subnetwork = var.svpc_subnet
      master_ipv4_cidr_block               = var.gke_control_plane_cidr_block
    }
  }
}