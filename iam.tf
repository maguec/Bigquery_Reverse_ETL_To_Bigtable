# Fake connection
resource "google_bigquery_connection" "fake" {
  connection_id = "fake-psc-link"
  location      = var.location
  friendly_name = "Fake PSC Connection"
  cloud_resource {}
}

resource "google_service_account" "lab_service_account" {
  project      = var.gcp_project_id
  account_id   = "account-${local.suffix}"
  display_name = "Service Account ${local.suffix}"
}

resource "google_project_iam_binding" "project" {
  project = var.gcp_project_id
  role    = "roles/bigtable.admin" # required because we update the BT with the reverse ETL

  members = [
    "serviceAccount:${google_service_account.lab_service_account.email}"
  ]
}

resource "google_project_iam_binding" "project-bq" {
  project = var.gcp_project_id
  role    = "roles/bigquery.dataViewer"

  members = [
    "serviceAccount:${google_service_account.lab_service_account.email}"
  ]
}

resource "google_project_iam_binding" "project-bq-job" {
  project = var.gcp_project_id
  role    = "roles/bigquery.jobUser"

  members = [
    "serviceAccount:${google_service_account.lab_service_account.email}"
  ]
}

resource "google_project_iam_member" "bq_user_role" {
  project = var.gcp_project_id
  role    = "roles/bigquery.user" # This includes the 'bigquery.reservations.use' permission
  member  = "serviceAccount:${google_service_account.lab_service_account.email}"
}

resource "google_project_iam_binding" "alloydb_role" {
  project = var.gcp_project_id
  role    = "roles/alloydb.client"
  members = ["serviceAccount:service-${data.google_project.project.project_id}@gcp-sa-bigqueryconnection.iam.gserviceaccount.com"]
}

