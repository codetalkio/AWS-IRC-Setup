# This script will install UnrealIRCd 4.0.0 RC3 on an AWS Linux AMI by:
#   0) Create an AWS Linux EC2 instance, with S3 read access (IAM roles))
#   1) Installing the necessary packages with yum
#   2) Downloading unrealircd
#   3) Configuring and installing unrealircd
#   4) Generating SSL certificates
#   5.1) Download configuration files from S3, add init script and start it
#   5.2) Alternatively, do it manually
#
# S3 assumes the file is called $UNREAL_VERSION-conf.tar.gz, and is unpacked to
# unrealircd-conf`.
#
# NOTE: Expects root priviliges i.e. `sudo install-unrealircd.sh`
#

# UnrealIRCd version
UNREAL_VERSION="unrealircd-4.0.0-rc3"
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
LC_ALL=C

# Make sure the ircd group exists
groupadd ircd

# Install necessary packages and clean up afterwards
export INSTALL_COMPLETE="no"
echo "> Starting installation" \
    && yum -yq upgrade \
    && yum -yq groupinstall "Development Tools" \
    && yum -yq install \
           curl \
           libcurl-devel \
           openssl-devel \
           openssl zlib \
           zlib-devel \
           ntp \
           c-ares \
    && yum -yq autoremove \
    && curl https://www.unrealircd.org/downloads/$UNREAL_VERSION.tar.gz \
        | tar xz \
    && cd $UNREAL_VERSION \
    && ./configure \
        --enable-ssl \
        --with-showlistmodes \
        --with-shunnotices \
        --with-confdir=/etc/unrealircd/config \
        --with-cachedir=/etc/unrealircd/cache \
        --with-scriptdir=/etc/unrealircd/unreal \
        --with-tmpdir=/etc/unrealircd/tmp \
        --with-modulesdir=/etc/unrealircd/modules \
        --with-logdir=/etc/unrealircd/log \
        --with-docdir=/etc/unrealircd/doc \
        --with-datadir=/etc/unrealircd/data \
        --with-pidfile=/etc/unrealircd/pid \
        --with-bindir=/usr/bin/unrealircd \
        --with-permissions=0600 \
        --enable-dynamic-linking \
    && make \
    && make install \
    && mkdir -p /etc/unrealircd \
    && openssl req \
        -x509 \
        -newkey rsa:2048 \
        -keyout server.key.pem \
        -out server.cert.pem \
        -days $SSL_CERTIFICATE_DAYS \
        -nodes \
        -subj "/C=$SSL_CERTIFICATE_COUNTRY/ST=$SSL_CERTIFICATE_STATE/L=$SSL_CERTIFICATE_LOCATION/O=$SSL_CERTIFICATE_ORGANIZATION/OU=$SSL_CERTIFICATE_ORGANIZATION_UNIT/CN=$SSL_CERTIFICATE_COMMON_NAME" \
    && mv server.cert.pem /etc/unrealircd/config/ssl/ \
    && mv server.key.pem /etc/unrealircd/config/ssl/ \
    && chown -R :ircd /etc/unrealircd \
    && export INSTALL_COMPLETE="yes" \
    && echo "\n\n> Done installing"

if [ "$INSTALL_COMPLETE" == "yes" ]; then
    echo "> Setting up configuration"
    if [ "$USE_AWS" == "yes" ]; then
        echo "> Using AWS to configure"
        # Download and move the configuration files into place, from S3 (assuming EC2 roles are set)
        cd /etc/unrealircd/config \
            && aws s3 cp --region $AWS_S3_REGION s3://$AWS_S3_BUCKET/config/$UNREAL_VERSION-conf.tar.gz $UNREAL_VERSION-conf.tar.gz \
            && tar xf $UNREAL_VERSION-conf.tar.gz \
            && rm -f $UNREAL_VERSION-conf.tar.gz \
            && mv unrealircd-conf/unrealircd.conf unrealircd.conf \
            && mv unrealircd-conf/ircd.motd ircd.motd \
            && mv unrealircd-conf/conf conf \
            && mv unrealircd-conf/unreal-$OS.init /etc/init.d/unreal \
            && chmod +x /etc/init.d/unreal \
            && rm -rf unrealircd-conf \
            && echo "\n> Configuration has been downloaded and moved into place." \
            && chkconfig --add unreal \
            && service unreal start \
            && echo "> UnrealIRCd service has been started"
    else
        # Additional steps for manual configuration
        echo "> UnrealIRCd now needs to be configured. You can find most files at /etc/unrealircd."
        echo "A good starting point is:"
        echo "    cp /etc/unrealircd/config/examples/example.conf /etc/unrealircd/config/unrealircd.conf"
        echo "followed by editing the file to your fit."
    fi
else
    echo "\n\n> Something went wrong during the install. Please check the output."
fi

