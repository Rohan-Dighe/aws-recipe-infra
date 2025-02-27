# aws-recipe-infra
A cloud infrastructure which facilitates creation of zip-archives of recipes and their exchange in a streamlined and secure way.
Overview
This project implements a secure and scalable architecture for storing, processing, and distributing recipe files using AWS services. It utilizes Terraform for infrastructure as code (IaC) and AWS Lambda for automation. The architecture is designed for efficient file management, versioning, and secure global distribution through Amazon S3 and CloudFront.

Architecture Components
1. Amazon S3 (Storage & Archiving)
recipe_storage S3 Bucket: Stores incoming recipe files.
recipe_archives S3 Bucket: Stores processed (zipped) recipe files for long-term archiving.
S3 Versioning & Encryption: Ensures data integrity and security.
S3 Lifecycle Rules: Moves older files to Glacier and deletes expired files.
2. AWS Lambda (Automation & Processing)
Lambda Function (zip_recipes):
Automatically triggers when a file is uploaded to recipe_storage.
Downloads the file, compresses it into a ZIP, and uploads it to recipe_archives.
3. AWS CloudFront (Global Distribution)
CloudFront Distribution:
Provides secure global access to archived recipes.
Uses an Origin Access Identity (OAI) to restrict direct S3 access.
4. IAM Roles & Policies (Access Control)
IAM Role for Lambda to access S3.
IAM Policies to enforce security best practices.



# Project directory structure Explained !

![image](https://github.com/user-attachments/assets/1427685f-3519-43c5-a81d-1580c84bfdc3)

# overview
This project uses Terraform to provision and manage cloud infrastructure efficiently. The configuration is designed to be modular, scalable, and easily maintainable.

 Prerequisites
Before initializing the project, ensure you have the following installed:

Terraform (Latest stable version)
Cloud Provider CLI (e.g., AWS CLI, Azure CLI, GCP SDK)
Access credentials for the cloud provider

 Run aws configure and provide the Access Key Id and Secret Access Key and in my project i have used us-east-1 region.

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

# Once project deployed through terraform on AWS cloud use the below steps to access the zip file

Verify CloudFront HTTPS Access
Step 1: Get the CloudFront Distribution URL
1.	Go to AWS Console → CloudFront
2.	Find your CloudFront distribution
3.	Copy the Distribution Domain Name (e.g., d123example.cloudfront.net)

   For example : https://d123example.cloudfront.net/testfile.zip



