#  Add the BQ binding for the AlloyDB service account
# resource "google_project_iam_binding" "bqbinding" {
#   project = var.gcp_project_id
#   role    = "roles/bigquery.connectionUser"
# 
#   members = [
#     "serviceAccount:service-${data.google_project.project.number}@gcp-sa-alloydb.iam.gserviceaccount.com"
#   ]
# }

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
