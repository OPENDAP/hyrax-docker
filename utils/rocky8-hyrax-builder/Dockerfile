###############################################################################################
# 
# Dockerfile to construct an HEL9 (aka rocky9) host which is primed to which to build
# and package the Hyrax C++ compnents: libdap4 and bes.
# The rpm production software is installed and a mount point for rpm retrievalis created.
#
# Some shell state reference:
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
#
# In general use "set -e" when running commands that matter and don't use
# it for debugging stuff.
#
# Set one or more individual labels
FROM rockylinux:8
ENV ARCH="x86_64"
ENV java_version="java-11-openjdk"
ENV python_version="3.11"

LABEL vendor="OPeNDAP"
LABEL maintainer="support@opendap.org"

USER root



ENV HR="##########################################################################"

################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.

RUN set -e \
    && echo "$HR" \
    && echo "# Running dnf update" \
    && dnf update  -y \
    && echo "# Installing dnf config-manager" \
    && dnf install -y 'dnf-command(config-manager)' \
    # Enable crb so we can get the libtirpc and libtirpc-devel
#    && dnf config-manager --set-enabled "crb"
    # Set up our friends dnf-plugins-code, epel, and codeready-builder-for-rhel-9
    && dnf install -y dnf-plugins-core epel-release \
#    && yum clean all
#
#RUN set -e \
    && echo "$HR" \
    && echo "# Installing cURL" \
    && yum install -y curl --allowerasing \
    && yum install -y curl-devel  \
    && curl --version \
#    && yum clean all
#
# RUN set -e \
    && echo "$HR" \
    && echo "# Installing sqlite and sqlite-devel via yum packages" \
    && yum install -y sqlite sqlite-devel \
    && pkg-config --exists sqlite3 \
    && echo "# sqlite and sqlite-devel installed via yum packages" \
#    && echo "$HR"
#
#RUN set -e \
    && echo "$HR" \
    && echo "# Installing zstd, libzstd, libzstd-devel via yum packages" \
    && yum install -y zstd libzstd-devel \
    && pkg-config --list-all \
    && pkg-config --exists libzstd \
    && echo "# zstd, libzstd, libzstd-devel installed via yum packages" \
#    && yum clean all
#
# The things!
#RUN set -e \
    && echo "$HR" \
    && echo "# Installing All The Packages.." \
    && yum install -y libtirpc  libtirpc-devel \
    && yum install -y procps git gcc-c++ flex bison cmake autoconf automake libtool emacs bzip2 vim bc \
    && yum install -y valgrind gdb unzip which jq diffutils sqlite sqlite-devel \
    && yum install -y openssl-devel libuuid-devel readline-devel zlib-devel bzip2-devel \
    && yum install -y libjpeg-devel libxml2-devel libicu-devel \
    && yum install -y rpmdevtools rpmlint \
#    && yum clean all
#
# It's Java Time Witches!
#RUN set -e \
    && echo "$HR" \
    && echo "# Installing java version $java_version" \
    && dnf install -y "$java_version" "$java_version-devel" \
    && echo "# Switching to  java version: $java_version.$ARCH" \
    && alternatives --set java "$java_version.$ARCH" \
    && echo "# ava version: $(java -version)" \
    && java -version \
#    && yum clean all
#RUN set -e  \
#    && yum install -y openjpeg2-devel jasper-devel
#
#RUN set -e  \
#    && yum config-manager --set-enabled powertools \
#
#RUN set -e  \
#    && yum install -y cppunit cppunit-devel
#
#RUN set -e \
    && echo "$HR" \
    && echo "# It's AWS CLI Time People!" \
    && echo "# Installing Python $python_version" \
    && dnf install -y python$python_version \
    && echo "# Python version is: $(python3 --version)" \
    && echo "# Updating pip" \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3 \
    && python3 -m pip install --upgrade pip \
    && echo "# Installing aws cli" \
    && python3 -m pip install --no-cache-dir awscli \
    && echo "# aws cli version: $(aws --version)" \
#    && yum clean all
#
# RUN  set -e \
    && echo "# diff is here: $(which diff)" \
    && echo "$HR" \
    && yum clean all

# We need to make sure there is a directory/mount_point for the calling process
# to mount a volume that will receieve the RPM files.
RUN set -e \
    && echo "# I AM THE USER $(whoami)" \
    && mkdir -vp "$HOME/rpmbuild" \
    && echo "# HOME: $HOME"

# RUN ls -l /usr/libexec/

RUN export BUILD_DATE=`date +%s`
RUN echo "# BUILD_DATE: ${BUILD_DATE}"

ENTRYPOINT [ "/bin/bash" ]

USER root

CMD ["-"]

