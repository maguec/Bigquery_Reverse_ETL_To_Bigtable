# AlloyDB and BigQuery - Better together

Spin up AlloyDB and BigQuery and show how they can work together

## Usage

### Create a variables file
```bash
cp tfvars.example tester.tfvars
```

### Initialize and apply
```bash
terraform init
terraform apply -var-file tester.tfvars
```

### terraform doesn't yet support alloy for BQ so run the generated command
```bash
cat bq_command  |sh
```

