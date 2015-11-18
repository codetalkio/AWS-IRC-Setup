# AWS IRC Setup
Quickly setup an AWS EC2 instance with UnrealIRCd and Anope IRC services.

1. Upload files to S3[1]
    1. Upload configuration to `s3://YourBucket/config/`
    2. Upload install scripts to `s3://YourBucket/install/ `
2. Create an EC2 instance[2]:
    1. Set IAM to a role with [S3 read rights](#limited-s3-bucket-policy-iam)
    2. In the user data section under advanced, add the `init-ec2.sh` script
3. Launch the instance
4. Attach an Elastic IP to it
5. Done!


Steps 1.1 and 1.2 are handled by the `upload-to-s3.sh` script.

Steps 2, 3 and 4 are handled by the `launch-ec2-instance.sh` script.


# Limited S3 bucket policy (IAM)
The following policy allows `Get`, `Delete` and `Put` actions on all items in the `irc.codetalk.io` bucket. Note, that it does not allow listing the contents in it.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1447546160000",
            "Effect": "Allow",
            "Action": [
                "s3:DeleteObject",
                "s3:GetObject",
                "s3:PutObject"
            ],
            "Resource": [
                "arn:aws:s3:::YourBucket/*"
            ]
        }
    ]
}
```

Create the policy under AWS Console -> IAM -> Policy -> Create Policy. Then you can attach it to a user or group.
