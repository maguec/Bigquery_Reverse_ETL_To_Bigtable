output "a-bt-command" {
  value = "\nbq query --use_legacy_sql=false  'select * FROM data_${local.suffix}.customers LIMIT 10'\n"
}

output "bq-reverse-etl-command" {
  value = "\n${data.template_file.bq_command.rendered}\n"
}
