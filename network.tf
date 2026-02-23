resource "google_compute_address" "static" {
  project    = var.gcp_project_id
  region     = join("-", slice(split("-", var.gcp_zone), 0, 2))
  name       = "ipv4-${local.suffix}"
  depends_on = [google_project_service.compute, google_project_service.servicenetworking]
}

resource "google_compute_network" "vpc" {
  project                 = var.gcp_project_id
  name                    = "vpc-${local.suffix}"
  auto_create_subnetworks = false # Best practice for PSC to prevent IP overlaps
  depends_on              = [google_project_service.compute, google_project_service.servicenetworking]
}

resource "google_compute_firewall" "full_access_for_user" {
  project = var.gcp_project_id
  name    = "firewall-${local.suffix}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "5432"] # Added 6379 for alloydb/Valkey access
  }

  source_ranges = ["0.0.0.0/0"]
}

#############################################################################
# PSC Setup
#############################################################################

resource "google_compute_subnetwork" "psc_subnet" {
  project       = var.gcp_project_id
  name          = "subnet-${local.suffix}"
  ip_cidr_range = "10.0.0.240/28" # Ensure this range is available in your VPC
  region        = join("-", slice(split("-", var.gcp_zone), 0, 2))
  network       = google_compute_network.vpc.id
}

# Valkey and alloydb use different service classes - this was a huge time sink

resource "google_network_connectivity_service_connection_policy" "psc-alloydb" {
  project       = var.gcp_project_id
  name          = "psc-alloydb-${local.suffix}"
  location      = join("-", slice(split("-", var.gcp_zone), 0, 2))
  service_class = "google-cloud-alloydb"
  description   = "PSC Policy for AlloyDB "
  network       = "projects/${var.gcp_project_id}/global/networks/${google_compute_network.vpc.name}"
  psc_config {
    subnetworks = [google_compute_subnetwork.psc_subnet.id]
  }
  depends_on = [google_compute_subnetwork.psc_subnet]
}
