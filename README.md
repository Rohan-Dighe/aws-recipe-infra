# aws-recipe-infra
A cloud infrastructure which facilitates creation of zip-archives of recipes and their exchange in a streamlined and secure way.

# Project directory structure Explained !

![image](https://github.com/user-attachments/assets/1427685f-3519-43c5-a81d-1580c84bfdc3)

# 📌 Overview
This project uses Terraform to provision and manage cloud infrastructure efficiently. The configuration is designed to be modular, scalable, and easily maintainable.

📌 Prerequisites
Before initializing the project, ensure you have the following installed:

Terraform (Latest stable version)
Cloud Provider CLI (e.g., AWS CLI, Azure CLI, GCP SDK)
Access credentials for the cloud provider

# Run aws configure and provide the Access Key Id and Secret Access Key and in my project i have used us-east-1 region.

# Package the Lambda Code

cd lambda/
zip lambda_function.zip lambda_function.py
mv lambda_function.zip ..

# Initialize & Deploy with Terraform

# Initialize Terraform (download required providers)
terraform init

# # Validate Terraform files for syntax errors
terraform validate

# Preview infrastructure changes before applying
terraform plan

# Deploy infrastructure
terraform apply -auto-approve


