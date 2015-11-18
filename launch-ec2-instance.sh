#!/bin/bash

# AWS user credentials
export AWS_ACCESS_KEY_ID=MyAccessKey
export AWS_SECRET_ACCESS_KEY=MySecretKey
export AWS_DEFAULT_REGION=eu-central-1

# EC2 instance details
NAME_TAG="irc.myserver.org"
IMAGE_ID="ami-bc5b48d0" # Amazon Linux AMI 2015.09.1 (HVM), SSD Volume Type
SNAPSHOT_ID="snap-f1a95375" # That snapshot depends on the AMI above
INSTANCE_TYPE="t2.micro"
KEY_NAME="irc-server"
SECURITY_GROUP="IRC"
IAM_ROLE="irc.codetalk.io"
ELASTIC_IP=52.29.4.199

# Launch an EC2 instance
echo "> Launching the EC2 instance..."
INSTANCE_ID=$( aws ec2 run-instances \
    --image-id $IMAGE_ID \
    --instance-type $INSTANCE_TYPE \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP \
    --iam-instance-profile Name=$IAM_ROLE \
    --block-device-mapping DeviceName=/dev/xvda,Ebs="{SnapshotId=$SNAPSHOT_ID,VolumeSize=30,DeleteOnTermination=true,VolumeType=gp2}" \
    --user-data file://initec2.sh \
    | jq --raw-output '.Instances[0].InstanceId' )
echo "> Instance $INSTANCE_ID is launching"

# Add name, environment and company tags to the instance
echo "> Adding tags to the instance $INSTANCE_ID"
aws ec2 create-tags \
    --resources $INSTANCE_ID \
    --tags "[
        {\"Key\": \"Name\", \"Value\": \"$NAME_TAG\"}
    ]"

# Waiting for the instance to be running
echo "> Waiting until $INSTANCE_ID is running..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID
echo "> Instance is up"

# Associate an elastic IP with the instance
echo "> Associating the IP $ELASTIC_IP with instance $INSTANCE_ID"
ASSOC_ID=$( aws ec2 associate-address --instance-id $INSTANCE_ID --public-ip $ELASTIC_IP )
echo "> Done!"
