module "composer_project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 12.0"

  name            = "${var.project_prefix}-composer"
  org_id          = var.org_id
  billing_account = var.billing_account_id

  svpc_host_project_id = var.host_project_id
  shared_vpc_subnets   = [var.svpc_subnet]

  grant_services_network_role = false

  activate_apis = [
    "composer.googleapis.com"
  ]
}

# Incompatible Org Policies
# https://cloud.google.com/composer/docs/troubleshooting-environment-creation#incompatible_organizational_policies
module "serial_port_logging" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  constraint  = "constraints/compute.disableSerialPortLogging"
  policy_type = "boolean"
  policy_for  = "project"
  project_id  = module.composer_project.project_id
  enforce     = false
}

module "os_login" {
  source  = "terraform-google-modules/org-policy/google"
  version = "~> 5.1"

  constraint  = "constraints/compute.requireOsLogin"
  policy_type = "boolean"
  policy_for  = "project"
  project_id  = module.composer_project.project_id
  enforce     = false
}