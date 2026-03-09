resource "google_compute_instance" "vm" {
  name         = "vm-${local.suffix}"
  machine_type = var.machine_type
  zone         = var.gcp_zone
  tags         = ["full-access-${local.suffix}"]
  project      = var.gcp_project_id

  service_account {
    email  = google_service_account.lab_service_account.email
    scopes = ["cloud-platform"] # Google recommended
  }

  metadata_startup_script = templatefile(
    "startup_script.sh",
    {
      projectid : var.gcp_project_id,
      suffix : local.suffix,
      memorystore_ip : google_memorystore_instance.valkey.endpoints[0].connections[0].psc_auto_connection[0].ip_address,
      bq_purchases_command : data.template_file.bq_purchases_command.rendered,
      bq_profiles_command : data.template_file.bq_profiles_command.rendered
    },
  )

  boot_disk {
    initialize_params {
      image = data.google_compute_image.image.self_link
    }
  }

  network_interface {
    network    = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.psc_subnet.id
    dynamic "access_config" {
      for_each = var.enable_external ? [1] : []
      content {
        nat_ip = google_compute_address.static[0].address
      }
    }
  }

  shielded_instance_config {
    enable_secure_boot = true
  }


  # Stop updating if the boot disk changes
  lifecycle {
    ignore_changes = [boot_disk]
  }

  depends_on = [google_project_service.compute, google_project_service.servicenetworking]
}
