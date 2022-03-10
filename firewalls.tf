# Configure firewall rules
# https://cloud.google.com/composer/docs/how-to/managing/configuring-private-ip#step_3_configure_firewall_rules
resource "google_compute_firewall" "ea_composer_dns" {
  project     = var.host_project_id
  name        = "ea-composer-dns"
  network     = var.svpc_network
  description = "Allow egress from GKE Node IP range to any destination (0.0.0.0/0), TCP/UDP port 53."

  direction               = "EGRESS"
  target_service_accounts = [module.composer_project.service_account_email]
  destination_ranges      = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["53"]
  }

  allow {
    protocol = "udp"
    ports    = ["53"]
  }
}

resource "google_compute_firewall" "ea_composer_gke_node" {
  project     = var.host_project_id
  name        = "ea-composer-gke-all"
  network     = var.svpc_network
  description = "Allow egress from GKE Node IP range to GKE Node and Pod IP range, all ports."

  direction               = "EGRESS"
  target_service_accounts = [module.composer_project.service_account_email]
  destination_ranges      = [data.google_compute_subnetwork.subnet.ip_cidr_range, data.google_compute_subnetwork.subnet.secondary_ip_range[0].ip_cidr_range]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "ea_composer_gke_control" {
  project     = var.host_project_id
  name        = "ea-composer-gke-control"
  network     = var.svpc_network
  description = "Allow egress from GKE Node IP range to GKE Control Plane IP range"

  direction               = "EGRESS"
  target_service_accounts = [module.composer_project.service_account_email]
  destination_ranges      = [var.gke_control_plane_cidr_block]

  allow {
    protocol = "tcp"
    ports    = ["443", "10250"]
  }
}

resource "google_compute_firewall" "ia_composer_gke_hc" {
  project     = var.host_project_id
  name        = "ia-composer-gke-hc"
  network     = var.svpc_network
  description = "Allow ingress from GCP Health Checks 130.211.0.0/22, 35.191.0.0/16 to GKE Node IP range, TCP ports 80 and 443."

  direction               = "INGRESS"
  source_ranges           = data.google_netblock_ip_ranges.health_checks.cidr_blocks_ipv4
  target_service_accounts = [module.composer_project.service_account_email]


  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
}

resource "google_compute_firewall" "ea_composer_gke_googleapis" {
  project     = var.host_project_id
  name        = "ea-composer-gke-googleapis"
  network     = var.svpc_network
  description = "Allow egress from GKE Node IP range to IP addresses used for Google services."

  direction               = "EGRESS"
  target_service_accounts = [module.composer_project.service_account_email]
  destination_ranges      = data.google_netblock_ip_ranges.google.cidr_blocks_ipv4

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}

data "google_netblock_ip_ranges" "health_checks" {
  range_type = "health-checkers"
}

data "google_netblock_ip_ranges" "google" {
  range_type = "google-netblocks"
}

data "google_compute_subnetwork" "subnet" {
  project = var.host_project_id
  name    = basename(var.svpc_subnet)
  region  = "us-central1"
}