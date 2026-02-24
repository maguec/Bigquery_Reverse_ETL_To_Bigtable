resource "google_bigtable_instance" "bt" {
  name = "bt-i-${local.suffix}"

  cluster {
    cluster_id   = "bt-${local.suffix}"
    zone         = var.gcp_zone
    num_nodes    = 1
    storage_type = "HDD"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_bigtable_table" "profiles" {
  name          = "bt-t-profiles-${local.suffix}"
  instance_name = google_bigtable_instance.bt.name
  lifecycle {
    prevent_destroy = false
  }
  change_stream_retention = "0"
}

resource "google_bigtable_table" "purchases" {
  name          = "bt-t-purchases-${local.suffix}"
  instance_name = google_bigtable_instance.bt.name
  lifecycle {
    prevent_destroy = false
  }
  change_stream_retention = "0"
}

resource "google_bigtable_app_profile" "ap" {
  instance       = google_bigtable_instance.bt.name
  app_profile_id = "bt-profile"

  // Requests will be routed to the following cluster.
  single_cluster_routing {
    cluster_id                 = "bt-${local.suffix}"
    allow_transactional_writes = true
  }

  standard_isolation {
    priority = "PRIORITY_LOW"
  }

  ignore_warnings = true
}
