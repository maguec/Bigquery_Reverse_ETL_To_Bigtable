# output "bq-reverse-etl-load-profiles" {
#   value = "bq query < bq_profile_command --use_legacy_sql=false"
# }
# 
# output "bq-reverse-etl-load-purchases" {
#   value = "bq query < bq_purchases_command --use_legacy_sql=false"
# }

output "vm_ssh_command" {
  value = "gcloud compute ssh --zone ${var.gcp_zone} vm-${local.suffix} --project ${var.gcp_project_id}"
}
