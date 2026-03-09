# Bigtable and BigQuery - Better together


Use terraform to spin up the necessary resources on your own outside of the labratory environment

### Create a variables file
```bash
cp tfvars.example tester.tfvars
```

### Initialize and apply
```bash
terraform init
terraform apply -var-file tester.tfvars
```

### ssh into the instance from the output command that looks like
```bash
vm_ssh_command = "gcloud compute ssh --zone us-west1-a vm-<<SUFFIX>> --project <<PROJECT>>"
```
*Note:* This command may appear differently depending on your environment


## Shutdown 

To shutdown all of the resources 

```bash
terraform destroy -var-file tester.tfvars
```

