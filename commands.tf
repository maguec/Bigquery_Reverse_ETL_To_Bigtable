data "template_file" "bq_command" {
  template = file("${path.module}/command.ctmpl")
  vars = {
    location   = var.location
    project_id = var.gcp_project_id
    hex        = local.suffix
  }
}

resource "local_file" "bq_command" {
  content         = data.template_file.bq_command.rendered
  filename        = "${path.module}/bq_command"
  file_permission = "0644"
}
