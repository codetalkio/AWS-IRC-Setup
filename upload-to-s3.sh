#!/bin/bash

# AWS user credentials
export AWS_ACCESS_KEY_ID=MyAccessKey
export AWS_SECRET_ACCESS_KEY=MySecretKey
export AWS_DEFAULT_REGION=eu-central-1
export S3_BUCKET="yourbucket"

# Anope version
ANOPE_VERSION="2.0.2"
# UnrealIRCd version
UNREAL_VERSION="unrealircd-4.0.0-rc3"

# Handle the install scripts
echo "> Uploading install scripts to S3"
aws s3 cp install/install-unrealircd.sh s3://$S3_BUCKET/install/install-unrealircd.sh
aws s3 cp install/install-anope.sh s3://$S3_BUCKET/install/install-anope.sh

# Handle the configuration files
echo "> Tar and gzip the config files" \
    && cd config \
    && tar -czf $UNREAL_VERSION-conf.tar.gz unrealircd-conf \
    && tar -czf anope-$ANOPE_VERSION-conf.tar.gz anope-conf \
    && cd .. \
    && mv config/$UNREAL_VERSION-conf.tar.gz . \
    && mv config/anope-$ANOPE_VERSION-conf.tar.gz . \
    && echo "> Uploading configuration files to S3" \
    && aws s3 cp $UNREAL_VERSION-conf.tar.gz s3://$S3_BUCKET/config/$UNREAL_VERSION-conf.tar.gz \
    && aws s3 cp anope-$ANOPE_VERSION-conf.tar.gz s3://$S3_BUCKET/config/anope-$ANOPE_VERSION-conf.tar.gz \
    && echo "> Cleaning up tar.gz files" \
    && rm $UNREAL_VERSION-conf.tar.gz \
    && rm anope-$ANOPE_VERSION-conf.tar.gz \
    && echo "> Done!"

