Terraform commands : 

Initialize Terraform: terraform init
Plan infra : terraform plan
Apply the template : terraform apply -auto-approve
Delete the infra : terraform destroy -auto-approve

Control plane only runs Kubernetes system pods & worker runs the blue/green app.

terraDir
├── cluster
│   ├── main.tf
│   ├── terraform.tfvars
│   └── variables.tf
└── kubeIng
    ├── ingress.tf
    └── providers.tf

