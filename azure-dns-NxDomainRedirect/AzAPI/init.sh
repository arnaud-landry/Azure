az login
az login --tenant <tenant-id>
az account set --subscription "xxxx-xxxx-xxxx-xxxx-xxxx"
export TF_LOG=TRACE
terraform init
terraform plan