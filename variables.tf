# variables.tf

variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The EC2 instance type for the homework server."
  type        = string
  default     = "t2.micro"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block for allowed SSH access to the EC2 instance."
  type        = string
  default     = "0.0.0.0/0"  # Change this to restrict SSH access to specific IPs.
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance."
  type        = string
  default     = "ami-020cba7c55df1f615"  # Ubuntu AMI
}

variable "key_pair_name" {
  description = "The name of the key pair to associate with the EC2 instance."
  type        = string
  default     = "my-key-pair"  # Use your actual key pair name here.
}
