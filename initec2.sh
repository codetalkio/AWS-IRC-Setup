#!/bin/bash

# Bucket location
export AWS_S3_BUCKET="YourBucket/install"
export AWS_DEFAULT_REGION=eu-central-1

# Download the files from S3
echo "Downloading install files" >> /home/ec2-user/log.txt
aws s3 cp --region $AWS_DEFAULT_REGION s3://$AWS_S3_BUCKET/install/install-unrealircd.sh /home/ec2-user/install-unrealircd.sh >> /home/ec2-user/log.txt
aws s3 cp --region $AWS_DEFAULT_REGION s3://$AWS_S3_BUCKET/install/install-anope.sh /home/ec2-user/install-anope.sh >> /home/ec2-user/log.txt

# Make the scripts executable
echo "Making scripts executable" >> /home/ec2-user/log.txt
chmod +x /home/ec2-user/install-unrealircd.sh >> /home/ec2-user/log.txt
chmod +x /home/ec2-user/install-anope.sh >> /home/ec2-user/log.txt

# Installing UnrealIRCd
echo "Starting install of UnrealIRCd (check log-unrealircd.txt)" >> /home/ec2-user/log.txt
touch /home/ec2-user/log-unrealircd.txt
/home/ec2-user/install-unrealircd.sh >> /home/ec2-user/log-unrealircd.txt

# Installing Anope
echo "Starting install of Anope (check log-anope.txt)" >> /home/ec2-user/log.txt
touch /home/ec2-user/log-anope.txt
/home/ec2-user/install-anope.sh >> /home/ec2-user/log-anope.txt
