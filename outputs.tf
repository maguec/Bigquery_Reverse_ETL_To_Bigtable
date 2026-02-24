output "a-bt-command" {
  value = "\nbq query --use_legacy_sql=false  'select * FROM data_${local.suffix}.customers LIMIT 10'\n"
}

output "bq-reverse-etl-command" {
  value = "\n##########################################\n${data.template_file.bq_purchases_command.rendered}\n##########################################\n"
}

output "bq-reverse-etl-command-2" {
  value = "\n##########################################\n${data.template_file.bq_profiles_command.rendered}\n##########################################\n"
}
