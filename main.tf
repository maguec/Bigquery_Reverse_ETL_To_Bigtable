provider "google" {
  project = var.gcp_project_id
  region  = join("-", slice(split("-", var.gcp_zone), 0, 2))
}
resource "random_id" "server" {
  byte_length = 8
}

locals {
  suffix         = var.suffix == "" ? random_id.server.hex : var.suffix
  external_count = var.enable_external ? 1 : 0
  nat_count      = var.enable_external ? 0 : 1
}

resource "google_project_service" "servicenetworking" {
  project                    = var.gcp_project_id
  service                    = "servicenetworking.googleapis.com"
  disable_dependent_services = var.disable_apis
  disable_on_destroy         = var.disable_apis
}

resource "google_project_service" "compute" {
  project                    = var.gcp_project_id
  service                    = "compute.googleapis.com"
  disable_dependent_services = var.disable_apis
  disable_on_destroy         = var.disable_apis
}

resource "google_project_service" "networkconnectivity" {
  project                    = var.gcp_project_id
  service                    = "networkconnectivity.googleapis.com"
  disable_dependent_services = var.disable_apis
  disable_on_destroy         = var.disable_apis
}

resource "google_project_service" "bqconnection" {
  project                    = var.gcp_project_id
  service                    = "bigqueryconnection.googleapis.com"
  disable_dependent_services = var.disable_apis
  disable_on_destroy         = var.disable_apis
}
