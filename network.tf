##################### Switch between Public IP and NAT ###################################
# This external IP is only added if the enable_external variable is set to tru no the default
resource "google_compute_address" "static" {
  count      = local.external_count
  project    = var.gcp_project_id
  region     = join("-", slice(split("-", var.gcp_zone), 0, 2))
  name       = "ipv4-${local.suffix}"
  depends_on = [google_project_service.compute, google_project_service.servicenetworking]
}

# If we don't have an external IP we need a router and NAT

resource "google_compute_router" "router" {
  count   = local.nat_count
  project = var.gcp_project_id
  name    = "router-${local.suffix}"
  network = google_compute_network.vpc.id
  region  = join("-", slice(split("-", var.gcp_zone), 0, 2))
}

# Add Cloud NAT
resource "google_compute_router_nat" "nat" {
  count                              = local.nat_count
  project                            = var.gcp_project_id
  name                               = "nat-${local.suffix}"
  router                             = google_compute_router.router[0].name
  region                             = google_compute_router.router[0].region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

#####################  END Switch between Public IP and NAT ###############################

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
    ports    = ["22"] # Added 6379 for featurestoredb/Valkey access
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

resource "google_network_connectivity_service_connection_policy" "psc-valkey" {
  project       = var.gcp_project_id
  name          = "psc-valkey-${random_id.server.hex}"
  location      = join("-", slice(split("-", var.gcp_zone), 0, 2))
  service_class = "gcp-memorystore"
  description   = "PSC Policy for Memorystore Valkey"
  network       = "projects/${var.gcp_project_id}/global/networks/${google_compute_network.vpc.name}"
  psc_config {
    subnetworks = [google_compute_subnetwork.psc_subnet.id]
  }
  depends_on = [google_compute_subnetwork.psc_subnet]
}
