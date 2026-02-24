# Fake connection
resource "google_bigquery_connection" "fake" {
  connection_id = "fake-psc-link"
  location      = var.location
  friendly_name = "Fake PSC Connection"
  cloud_resource {}
}

#  Add the AlloyDB binding for the BQ service account
resource "google_project_iam_member" "bqbind" {
  project    = var.gcp_project_id
  role       = "roles/alloydb.client"
  member     = "serviceAccount:${google_bigquery_connection.fake.cloud_resource[0].service_account_id}"
  depends_on = [google_bigquery_connection.fake]
}

resource "google_service_account" "lab_service_account" {
  project      = var.gcp_project_id
  account_id   = "account-${local.suffix}"
  display_name = "Service Account ${local.suffix}"
}

resource "google_project_iam_binding" "project" {
  project = var.gcp_project_id
  role    = "roles/bigtable.user"

  members = [
    "serviceAccount:${google_service_account.lab_service_account.email}"
  ]
}
