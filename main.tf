terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"

  # Keep the backend resources intact (no changes here)
  backend "s3" {
    bucket         = "physicstutors-terraform-state"
    key            = "homework-help/terraform.tfstate"
    region         = "us-east-1"
    profile        = "whykay"
    dynamodb_table = "whykay-bootstrap-dynamodb-table"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.region
  profile = "whykay"
}

# S3 Bucket Resources
resource "aws_s3_bucket" "homework_submissions_1" {
  bucket = "physicstutors-homework-submissions-1"

  tags = {
    Name        = "Homework Submissions"
    Environment = "Production"
  }
}

resource "aws_s3_bucket_versioning" "homework_submissions_versioning_1" {
  bucket = aws_s3_bucket.homework_submissions_1.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "homework_submissions_access_1" {
  bucket = aws_s3_bucket.homework_submissions_1.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_cors_configuration" "homework_submissions_cors_1" {
  bucket = aws_s3_bucket.homework_submissions_1.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["*"]  # Replace with EC2 public IP or domain
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "homework_submissions_bucket_policy_1" {
  bucket = aws_s3_bucket.homework_submissions_1.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3PutObject"
        Effect = "Allow"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.homework_submissions_1.arn}/*"
        Principal = "*"
        Condition = {
          IpAddress = {
            "aws:SourceIp" = "0.0.0.0/0"  # Adjust for a more secure setup
          }
        }
      },
      {
        Sid    = "AllowS3GetObject"
        Effect = "Allow"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.homework_submissions_1.arn}/*"
        Principal = "*"
      },
      {
        Sid    = "AllowS3ListBucket"
        Effect = "Allow"
        Action = "s3:ListBucket"
        Resource = aws_s3_bucket.homework_submissions_1.arn
        Principal = "*"
      }
    ]
  })
}

# DynamoDB Tables Resources
resource "aws_dynamodb_table" "homework_uploads_table_1" {
  name         = "HomeworkUploadsTable1"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Email"
  range_key    = "SignupTime"

  attribute {
    name = "Email"
    type = "S"
  }

  attribute {
    name = "SignupTime"
    type = "S"
  }

  tags = {
    Name        = "HomeworkUploadsTable1"
    Environment = "Production"
  }
}

resource "aws_dynamodb_table" "feedback_table_1" {
  name         = "FeedbackTable1"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Email"
  range_key    = "SignupTime"

  attribute {
    name = "Email"
    type = "S"
  }

  attribute {
    name = "SignupTime"
    type = "S"
  }

  tags = {
    Name        = "FeedbackTable1"
    Environment = "Production"
  }
}

resource "aws_dynamodb_table" "signups_table_1" {
  name         = "SignupsTable1"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Email"
  range_key    = "SignupTime"

  attribute {
    name = "Email"
    type = "S"
  }

  attribute {
    name = "SignupTime"
    type = "S"
  }

  tags = {
    Name        = "SignupsTable1"
    Environment = "Production"
  }
}

# SNS Topic Resources
resource "aws_sns_topic" "homework_submission_topic_1" {
  name = "Home-Work-Help-Submission-1"

  tags = {
    Name        = "HomeworkSubmissionTopic1"
    Environment = "Production"
  }
}

# IAM Role and Policies Resources
resource "aws_iam_role" "ec2_role_1" {
  name = "HomeworkHelpEC2Role1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_policy_1" {
  name   = "HomeworkHelpEC2Policy1"
  role   = aws_iam_role.ec2_role_1.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.homework_submissions_1.arn,
          "${aws_s3_bucket.homework_submissions_1.arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.homework_uploads_table_1.arn,
          aws_dynamodb_table.feedback_table_1.arn,
          aws_dynamodb_table.signups_table_1.arn
        ]
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = aws_sns_topic.homework_submission_topic_1.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile_1" {
  name = "HomeworkHelpEC2Profile1"
  role = aws_iam_role.ec2_role_1.name
}

# Security Group Resources (Updated to add `1` suffix)
resource "aws_security_group" "ec2_sg_1" {
  name        = "homework-help-ec2-sg-1"
  description = "Allow HTTP, SSH, and custom app traffic (port 3000)"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "HomeworkHelpSG1"
  }
}

# EC2 Instance Resources
resource "aws_instance" "homework_server_1" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_pair_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile_1.name
  vpc_security_group_ids = [aws_security_group.ec2_sg_1.id]
  user_data              = templatefile("${path.module}/user-data/user-data.sh", {
    bucket_name         = aws_s3_bucket.homework_submissions_1.bucket,
    homework_table_name = aws_dynamodb_table.homework_uploads_table_1.name,
    feedback_table_name = aws_dynamodb_table.feedback_table_1.name,
    signups_table_name  = aws_dynamodb_table.signups_table_1.name,
    sns_topic_arn       = aws_sns_topic.homework_submission_topic_1.arn,
    region              = var.region,
    server_js_content   = file("${path.module}/templates/server.js.tpl")
  })

  tags = {
    Name        = "HomeworkHelpServer1"
    Environment = "Production"
  }
}
