# Bigtable and BigQuery - Better together

Spin up Bigtable and BigQuery and show how they can work together using Reverse ETL

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
open up bigquery and run the reverset ETL command
```

