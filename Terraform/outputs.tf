output "vm_ssh_command" {
  value = "gcloud compute ssh --zone ${var.gcp_zone} vm-${local.suffix} --project ${var.gcp_project_id}${var.enable_external ? "" : " --tunnel-through-iap"}"
}
