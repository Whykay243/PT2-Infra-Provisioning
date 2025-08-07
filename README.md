# Homework Help Infrastructure

This repository contains the Terraform configuration for provisioning infrastructure related to the Homework Help system for `Physicstutors.org`. The infrastructure includes an EC2 instance with security groups, IAM roles, an S3 bucket, DynamoDB tables, and SNS topics, with checks in place to skip resource creation if they already exist.

## Overview

This project automates the provisioning of a backend infrastructure with the following components:

- **EC2 Instance**: A server for running the backend application with a custom key pair.
- **Security Group**: Custom security group for HTTP, SSH, and custom port (3000) access.
- **S3 Bucket**: For storing homework submissions, only created if it doesn't exist.
- **DynamoDB Tables**: For storing feedback, signups, and homework data, only created if they don't already exist.
- **SNS Topic**: To notify users when homework or feedback is submitted, only created if it doesn't already exist.

## Components

The main configuration is defined in `main.tf`, which combines all the resources and settings into a single file, including:

- **Backend Configuration**: The backend to store the Terraform state remotely in an S3 bucket and use DynamoDB for state locking. (`backend.tf` is included in `main.tf`).
- **EC2 Instance**: The EC2 instance to run the backend application, configured with a custom key pair.
- **Security Group**: The security group attached to the EC2 instance, with inbound rules for HTTP, SSH, and custom app traffic (port 3000).
- **S3 Bucket**: The S3 bucket for storing homework submissions.
- **DynamoDB Tables**: Tables for storing feedback, signups, and homework data.
- **SNS Topic**: The SNS topic for sending notifications about homework or feedback submission.
- **IAM Roles**: IAM roles and policies required for the EC2 instance to interact with AWS services.

## Files and Structure

- **`main.tf`**: This is the main configuration file that defines all the resources such as EC2 instance, security group, S3 bucket, DynamoDB tables, SNS topic, IAM roles, and more.
- **`variables.tf`**: File that contains all the variable definitions.
- **`terraform.tfvars`**: File for defining the variable values (e.g., instance type, allowed SSH CIDR).
- **`backend.tf`**: Backend configuration for Terraform to use an S3 bucket and DynamoDB for state locking (included in `main.tf`).
- **`scripts/`**: Folder containing helper scripts.
  - **`user-data.sh`**: A script to configure the EC2 instance upon launch.
- **`templates/`**: Folder containing template files.
  - **`server.js.tpl`**: Template for creating the `server.js` file for the backend.

## Prerequisites

Before deploying this infrastructure, make sure you have the following:

- **Terraform**: Installed and configured on your machine.
- **AWS CLI**: Installed and configured with appropriate IAM permissions.
- **AWS Account**: With permissions to create EC2, S3, DynamoDB, SNS, and IAM resources.
- **SSH Key Pair**: If using EC2, ensure you have a valid SSH key pair (e.g., `my-key-pair`) for SSH access to the instance.
- **AWS Profile**: Ensure the correct AWS profile is set (in this case, `Whykay`).

## Deployment Steps

1. **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/terraform-homework-help-infrastructure.git
    cd terraform-homework-help-infrastructure
    ```

2. **Initialize Terraform:**

    This command initializes the Terraform configuration and downloads the required provider plugins.

    ```bash
    terraform init
    ```

3. **Review the infrastructure plan:**

    This command shows what Terraform is going to do before it actually creates or modifies resources.

    ```bash
    terraform plan
    ```

4. **Apply the configuration:**

    Apply the Terraform configuration to create the infrastructure.

    ```bash
    terraform apply
    ```

    Terraform will ask for confirmation before making any changes. Type `yes` to proceed.

5. **Verify Resources:**

    After the apply completes, Terraform will output the details of the created resources (such as the EC2 instance public IP, S3 bucket name, etc.).

6. **Access the EC2 Instance:**

    After the infrastructure is provisioned, you can access the EC2 instance using SSH (if SSH access is enabled).

    ```bash
    ssh -i /path/to/your-key.pem ubuntu@<EC2_PUBLIC_IP>
    ```

## Files Explained

### `main.tf`
This is the main configuration file, which defines the following resources:

- **Backend configuration**: Uses S3 for remote state storage and DynamoDB for state locking.
- **EC2 instance**: Configured with the necessary IAM role, security group, and key pair for SSH access.
- **Security group**: Defines the rules for HTTP, SSH, and port 3000 access to the EC2 instance.
- **S3 bucket**: For homework submission storage, created only if it doesn't already exist.
- **DynamoDB tables**: For storing homework uploads, feedback, and signups.
- **SNS topic**: For sending notifications about homework or feedback submission.
- **IAM roles**: Defines the permissions required for the EC2 instance to interact with AWS services.

### `security_group.tf`
Defines the security group for the EC2 instance, allowing HTTP (port 80), SSH (port 22), and custom port 3000 for the backend server.

### `user-data.sh`
This script is executed upon EC2 instance launch. It sets up the backend environment, installs dependencies (Node.js, AWS SDK), and configures the server to run your backend application.

### `server.js.tpl`
A template for creating the `server.js` file for the backend. It sets up an Express server and connects to DynamoDB, SNS, and S3.

### `backend.tf`
Configured in `main.tf` for remote state storage using S3 and DynamoDB for state locking.

## Cleanup

To destroy the infrastructure created by Terraform, run the following command:

```bash
terraform destroy
