# This script will install Anope IRC Services on an AWS Linux AMI by:
#   0.1) Create an AWS Linux EC2 instance, with S3 read access (IAM roles))
#   0.2) Set up UnrealIRCd
#   1) Installing the necessary packages with yum
#   2) Downloading anope
#   3) Configuring and installing anope
#   4.1) Download configuration files from S3, add init script and start it
#   4.2) Alternatively, do it manually
#
# S3 assumes the file is called anope-$ANOPE_VERSION-conf.tar.gz, and is unpacked to
# anope-conf`.
#
# NOTE: Expects root priviliges i.e. `sudo install-anope.sh`
#

# Anope version
ANOPE_VERSION="2.0.2"
# Operating system (used for init script)
OS="centos"
# AWS S3 bucket configuration
USE_AWS="yes" # set to no, if you don't want to use S3
AWS_S3_BUCKET="YourBucket"
AWS_S3_REGION="eu-central-1"
# SSL certificate information
SSL_CERTIFICATE_COUNTRY="DK" # The two-letter ISO abbreviation for your country
SSL_CERTIFICATE_STATE="Copenhagen" # The state or province where your organization is legally located
SSL_CERTIFICATE_LOCATION="Copenhagen" # The city where your organization is legally located
SSL_CERTIFICATE_ORGANIZATION="MyOrganization" # The exact legal name of your organization
SSL_CERTIFICATE_ORGANIZATION_UNIT="IT" # Section of the organization
SSL_CERTIFICATE_COMMON_NAME="irc.myserver.org" # The fully qualified domain name for your web server
SSL_CERTIFICATE_DAYS=20000


# Set the correct locale environment
ENV LC_ALL C

# Make sure the ircd group exists
groupadd ircd

# Install necessary packages and clean up afterwards
export INSTALL_COMPLETE="no"
echo "> Starting installation" \
    && yum -y upgrade \
    && yum -y install cmake \
    && yum -y autoremove \
    && curl -L https://github.com/anope/anope/releases/download/$ANOPE_VERSION/anope-$ANOPE_VERSION-source.tar.gz \
        | tar xz \
    && cd anope-$ANOPE_VERSION-source \
    && mv modules/extra/m_ssl_openssl.cpp modules/ \
    && mv modules/extra/m_sasl_dh-aes.cpp modules/ \
    && mkdir build \
    && cd build \
    && cmake \
        -DINSTDIR:STRING=/etc/anope \
        -DDEFUMASK:STRING=077  \
        -DCMAKE_BUILD_TYPE:STRING=RELEASE \
        -DUSE_RUN_CC_PL:BOOLEAN=ON \
        -DUSE_PCH:BOOLEAN=ON .. \
    && make \
    && make install \
    && openssl genrsa -out anope.key 2048 \
    && openssl req \
        -new \
        -x509 \
        -key anope.key \
        -out anope.crt \
        -days $SSL_CERTIFICATE_DAYS \
        -subj "/C=$SSL_CERTIFICATE_COUNTRY/ST=$SSL_CERTIFICATE_STATE/L=$SSL_CERTIFICATE_LOCATION/O=$SSL_CERTIFICATE_ORGANIZATION/OU=$SSL_CERTIFICATE_ORGANIZATION_UNIT/CN=$SSL_CERTIFICATE_COMMON_NAME" \
    && mv anope.crt /etc/anope/data/ \
    && mv anope.key /etc/anope/data/ \
    && chown -R :ircd /etc/anope \
    && export INSTALL_COMPLETE="yes" \
    && echo "\n\n> Done installing"

if [ "$INSTALL_COMPLETE" == "yes" ]; then
    echo "> Setting up configuration"
    if [ "$USE_AWS" == "yes" ]; then
        echo "> Using AWS to configure"
        # Download and move the configuration files into place, from S3 (assuming EC2 roles are set)
        cd /etc/anope \
            && aws s3 cp --region $AWS_S3_REGION s3://$AWS_S3_BUCKET/config/anope-$ANOPE_VERSION-conf.tar.gz anope-$ANOPE_VERSION-conf.tar.gz \
            && tar xf anope-$ANOPE_VERSION-conf.tar.gz \
            && rm -f anope-$ANOPE_VERSION-conf.tar.gz \
            && rm -rf conf \
            && mv anope-conf/anope-$OS.init /etc/init.d/anope \
            && mv anope-conf conf \
            && echo "\n> Configuration has been downloaded and moved into place." \
            && chmod +x /etc/init.d/anope \
            && chkconfig --add anope \
            && service anope start \
            && echo "> Anope IRC services have been started"
    else
        # Additional steps for manual configuration
        echo "> Anope now needs to be configured. You can find most files at /etc/anope/conf."
        echo "\n> It is recommended to add the following via 'crontab -e'"
        echo "      5 * * * * /etc/anope/conf/services.chk >/dev/null 2>&1"
        echo "  and then running 'crontab -l' to check it."
    fi
else
    echo "\n\n> Something went wrong during the install. Please check the output."
fi

