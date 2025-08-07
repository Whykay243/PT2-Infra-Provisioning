#!/bin/bash
# Exit on any error
set -e

# Log setup progress
echo "Starting setup at $(date)" >> /home/ec2-user/setup.log

# Install Node.js and Nginx
echo "Installing Node.js and Nginx" >> /home/ec2-user/setup.log
curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
yum install -y nodejs nginx

# Create application directory
echo "Creating application directory" >> /home/ec2-user/setup.log
mkdir -p /home/ec2-user/feedback-backend
cd /home/ec2-user/feedback-backend

# Install dependencies
echo "Installing Node.js dependencies" >> /home/ec2-user/setup.log
npm init -y
npm install express cors @aws-sdk/client-dynamodb @aws-sdk/lib-dynamodb @aws-sdk/client-sns @aws-sdk/client-s3 @aws-sdk/s3-request-presigner uuid mime-types dotenv

# Create .env file with environment variables
echo "Creating .env file" >> /home/ec2-user/setup.log
cat << EOF > .env
BUCKET_NAME=${bucket_name}
HOMEWORK_TABLE_NAME=${homework_table_name}
FEEDBACK_TABLE_NAME=${feedback_table_name}
SIGNUPS_TABLE_NAME=${signups_table_name}
SNS_TOPIC_ARN=${sns_topic_arn}
REGION=${region}
EOF

# Write server.js (rendered by Terraform's templatefile)
echo "Writing server.js" >> /home/ec2-user/setup.log
cat << 'EOF' > server.js
${server_js_content}
EOF

# Configure Nginx for frontend
echo "Configuring Nginx" >> /home/ec2-user/setup.log
mkdir -p /usr/share/nginx/html
aws s3 cp s3://${bucket_name}/homeworkhelpsubmission.html /usr/share/nginx/html/ || {
  echo "Failed to copy homeworkhelpsubmission.html from S3" >&2
  exit 1
}
chown nginx:nginx /usr/share/nginx/html/homeworkhelpsubmission.html
chmod 644 /usr/share/nginx/html/homeworkhelpsubmission.html

cat << EOF > /etc/nginx/conf.d/homework-help.conf
server {
    listen 80;
    server_name _;

    location / {
        root /usr/share/nginx/html;
        index homeworkhelpsubmission.html;
    }

    location /api/ {
        proxy_pass http://localhost:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Test Nginx configuration
nginx -t -c /etc/nginx/nginx.conf || {
  echo "Nginx configuration test failed" >&2
  exit 1
}

# Start services
echo "Starting Nginx and Node.js" >> /home/ec2-user/setup.log
systemctl enable nginx
systemctl start nginx || {
  echo "Failed to start Nginx" >&2
  exit 1
}
nohup node server.js > server.log 2>&1 &
echo "Setup completed at $(date)" >> /home/ec2-user/setup.log
