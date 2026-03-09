resource "google_storage_bucket" "bqdata" {
  name                        = "data-stagingbucket-${local.suffix}"
  location                    = var.location
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "csv_upload" {
  name   = "data.csv"
  source = "local_data_file.csv"
  bucket = google_storage_bucket.bqdata.name
}

resource "google_bigquery_dataset" "bq" {
  project                     = var.gcp_project_id
  dataset_id                  = "data_${local.suffix}"
  friendly_name               = "data_${local.suffix}"
  description                 = "A Dataset we created to play nice with data-${local.suffix}"
  location                    = var.location
  default_table_expiration_ms = 3600000

  labels = {
    id = "${local.suffix}"
  }

}

resource "google_bigquery_table" "data" {
  dataset_id          = google_bigquery_dataset.bq.dataset_id
  table_id            = "customers"
  deletion_protection = false # don't do this in production

  labels = {
    id = "${local.suffix}"
  }

  external_data_configuration {
    autodetect    = true
    source_format = "CSV"
    source_uris = [
      "gs://${google_storage_bucket.bqdata.name}/${google_storage_bucket_object.csv_upload.name}"
    ]

    csv_options {
      quote = "\""
      #skip_leading_rows = 1 # Skip header row
    }
  }
  schema = <<EOF
[
  {
    "name": "id",
    "type": "NUMERIC",
    "description": "Customer ID"
  },
  {
    "name": "email",
    "type": "STRING",
    "description": "Customer Email Address"
  }
]
EOF

}

resource "google_bigquery_reservation" "reservation" {
  name              = "bq-reservation-${local.suffix}"
  location          = var.location
  slot_capacity     = 50
  edition           = "ENTERPRISE"
  ignore_idle_slots = true
  concurrency       = 0
  autoscale {
    max_slots = 50
  }
}

resource "google_bigquery_reservation_assignment" "assignment" {
  project     = var.gcp_project_id
  location    = var.location
  reservation = google_bigquery_reservation.reservation.id
  assignee    = "projects/${var.gcp_project_id}"
  job_type    = "QUERY"
}
