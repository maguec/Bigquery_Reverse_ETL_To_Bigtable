# Bigtable and BigQuery - Better together

Spin up Bigtable, Valkey and BigQuery and show how they can work together using Reverse ETL to provide low latency

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

### ssh into the instance from the outputput command that looks like
```bash
vm_ssh_command = "gcloud compute ssh --zone us-west1-a vm-<<SUFFIX>> --project <<PROJECT>>"
```

### After SSH-ing into the VM check out the repo for some sample code
```bash
git clone https://github.com/maguec/Bigquery_Reverse_ETL_To_Bigtable.git
cd Bigquery_Reverse_ETL_To_Bigtable/code
```

### Run the output commands to populate Bigtable from BQ Reverse ETL queries
```bash
bq query < /tmp/bq_profiles_command.sql --use_legacy_sql=false --location=US
bq query < /tmp/bq_purchases_command.sql --use_legacy_sql=false --location=US
```

### Grab some email addresses that we can use to view provfiles on the VM

#### List 25 addresses
```bash
cbt -instance bt-i-${BIGTABLE_SUFFIX} -project ${BIGTABLE_PROJECT} \
  read bt-t-purchases-${BIGTABLE_SUFFIX} count=25 | awk '/^-------/ {getline; print}'
```

#### Set one address as an env var
```bash
export EMAIL_ADDRESS=`cbt -instance bt-i-${BIGTABLE_SUFFIX} -project ${BIGTABLE_PROJECT} read bt-t-purchases-${BIGTABLE_SUFFIX} count=25 | awk '/^-------/ {getline; print}'|tail -1`
echo $EMAIL_ADDRESS
```

### View and configure a profile in the VM

#### View an un-cached profile
```bash
uv run fetch_profile.py ${EMAIL_ADDRESS} |jq
# Note the fetch time
uv run fetch_profile.py ${EMAIL_ADDRESS} |jq '.fetch_time, .source'
```

#### Cache the profile 
```bash
uv run cache_profile.py ${EMAIL_ADDRESS}
```

#### View the cached profile
```bash
uv run fetch_profile.py ${EMAIL_ADDRESS} |jq
# Note the fetch time
uv run fetch_profile.py ${EMAIL_ADDRESS} |jq '.fetch_time, .source'
```


### Add intent to a profile
```bash
uv run add_intent.py  ${EMAIL_ADDRESS} boots 20
uv run add_intent.py  ${EMAIL_ADDRESS} sneakers 3600
```

### View the profile and note the boots intent get TTL'd out in 20 seconds

```bash
uv run fetch_profile.py ${EMAIL_ADDRESS} |jq
sleep 20
uv run fetch_profile.py ${EMAIL_ADDRESS} |jq
```

### View the raw data in Bigtable

#### Profile
```bash
cbt -instance bt-i-${BIGTABLE_SUFFIX} -project ${BIGTABLE_PROJECT} read bt-t-profiles-${BIGTABLE_SUFFIX} count=20
```

#### Purchases
```bash
cbt -instance bt-i-${BIGTABLE_SUFFIX} -project ${BIGTABLE_PROJECT} read bt-t-purchases-${BIGTABLE_SUFFIX} count=20
```

### View the raw data in BigQuery

#### Profile
```bash
bq query 'SELECT * from bigquery-public-data.thelook_ecommerce.order_items WHERE status="Complete" LIMIT 10'
```


## Shutdown 

To shutdown all of the resources 

```bash
terraform destroy -var-file tester.tfvars
```

