data "template_file" "bq_purchases_command" {
  template = file("${path.module}/purchases_command.ctmpl")
  vars = {
    location   = var.location
    project_id = var.gcp_project_id
    hex        = local.suffix
  }
}

resource "local_file" "bq_purchases_command" {
  content         = data.template_file.bq_purchases_command.rendered
  filename        = "${path.module}/bq_purchases_command"
  file_permission = "0644"
}

data "template_file" "bq_profiles_command" {
  template = file("${path.module}/profile_command.ctmpl")
  vars = {
    location   = var.location
    project_id = var.gcp_project_id
    hex        = local.suffix
  }
}

resource "local_file" "bq_profile_command" {
  content         = data.template_file.bq_profiles_command.rendered
  filename        = "${path.module}/bq_profile_command"
  file_permission = "0644"
}
