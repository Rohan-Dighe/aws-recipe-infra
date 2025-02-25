# aws-recipe-infra
A cloud infrastructure which facilitates creation of zip-archives of recipes and their exchange in a streamlined and secure way.

# Project directory structure Explained !

aws-recipe-infra/
│── main.tf           # Main Terraform file (defines resources)
│── variables.tf      # Defines input variables
│── outputs.tf        # Defines output values
│── provider.tf       # AWS provider configuration
│── lambda/           # Lambda function code directory
│   └── lambda_function.py  # Python script for zipping recipes
│── terraform.tfvars  # Defines actual values for variables
