# terraform.tfvars

region          = "us-east-1"  # Replace with your preferred region if necessary
instance_type   = "t2.micro"   # Specify instance type if different
allowed_ssh_cidr = "0.0.0.0/0"  # Modify this to restrict SSH access if needed
ami_id          = "ami-020cba7c55df1f615"  # The AMI ID for Ubuntu
key_pair_name   = "my-key-pair"  # Your existing key pair name
