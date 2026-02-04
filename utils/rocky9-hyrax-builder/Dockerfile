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
FROM rockylinux:9
ENV ARCH="x86_64"
ENV java_version="java-21-openjdk"
ENV python_version="3.12"

ENV package_list="\
    libtirpc libtirpc-devel procps \
    git gcc-c++ flex bison cmake autoconf271 automake libtool \
    diffutils sqlite sqlite-devel openssl-devel libuuid-devel \
    readline-devel zlib-devel bzip2 bzip2-devel libjpeg-devel libxml2-devel \
    libicu-devel rpmdevtools rpmlint zstd libzstd-devel \
"
ENV dev_ui_packages="emacs vim bc valgrind gdb unzip which jq"


LABEL vendor="OPeNDAP"
LABEL maintainer="support@opendap.org"

USER root


ENV HR="###########################################################################"
ENV HR2="# -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - -- - --"


################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e \
    && echo "$HR" \
    && echo "# Running dnf update and configuration steps" \
    && dnf update  -y \
    && dnf install -y 'dnf-command(config-manager)' \
    # Enable crb so we can get the libtirpc and libtirpc-devel
    && dnf config-manager --set-enabled "crb" \
    # Set up our friends dnf-plugins-code, epel, and codeready-builder-for-rhel-9
    && dnf install -y dnf-plugins-core epel-release \
#    && yum clean all
#
# RUN set -e \
    && echo "$HR" \
    && echo "# Installing cURL" \
    && yum install -y curl curl-devel --allowerasing \
    && echo "# cURL version: $(curl --version)" \
#    && yum clean all
#
# RUN set -e \
#    && echo "$HR" \
#    && echo "# Installing sqlite and sqlite-devel via yum packages" \
#    && yum install -y sqlite sqlite-devel \
#    && pkg-config --exists sqlite3 \
#    && echo "# sqlite and sqlite-devel installed via yum packages" \
#    && yum clean all
#
# RUN set -e \
#    && echo "$HR" \
#    && echo "# Installing zstd, libzstd, libzstd-devel via yum packages" \
#    && yum install -y zstd libzstd-devel \
#    && pkg-config --list-all \
#    && pkg-config --exists libzstd \
#    && echo "# zstd, libzstd, libzstd-devel installed via yum packages" \
#    && yum clean all
#
# RUN set -e \
    && echo "$HR" \
    && echo "# Installing All The Packages.." \
    && yum install -y $package_list $dev_ui_packages \
    && pkg-config --exists sqlite3 \
    && echo "# sqlite and sqlite-devel installed via yum packages" \
    && pkg-config --exists libzstd \
    && echo "# zstd, libzstd, libzstd-devel installed via yum packages" \
#    && yum clean all
#
# RUN set -e \
    && echo "$HR" \
    && echo "# It's Java Time Witches!" \
    && echo "# Installing $java_version and ant." \
    && yum install -y "$java_version" "$java_version-devel"  \
# Do we need ant? Because it loads a completely independent java version stack which is ~150MB!
#    && yum install -y ant \
    && echo "$HR2" \
    && echo "# Using $java_version" \
    && update-alternatives --set java "$java_version.$ARCH" \
    && echo "# Enabled $java_version" \
    && echo "# java version: $( java -version 2>&1 )" \
#    && yum clean all
#
# RUN set -e  \
#    && yum install -y openjpeg2-devel jasper-devel
#
# RUN set -e  \
#    && yum config-manager --set-enabled powertools \
#
# RUN set -e  \
#    && yum install -y cppunit cppunit-devel
#
# RUN set -e \
    && echo "$HR" \
    && echo "# Installing Python $python_version" \
    && yum install -y python$python_version \
    && echo "# python version: $(python3 --version)" \
    && echo "$HR" \
    && echo "# Installing AWS CLI 2" \
    && yum install -y awscli2 \
    && echo "# aws cli version: $(aws --version)" \
    && yum clean all



RUN  set -e \
    && echo "#" \
    && echo "# diff is here: $(which diff)" \
    && yum clean all
#
# We need to make sure there is a directory/mount_point for the calling process
# to mount a volume that will receieve the RPM files.
RUN set -e \
    && echo "# I AM THE USER $(whoami)" \
    && mkdir -vp "$HOME/rpmbuild" \
    && echo "# HOME: $HOME"

# RUN ls -l /usr/libexec/

RUN export BUILD_DATE=`date +%s`
RUN echo "# BUILD_DATE: ${BUILD_DATE}"

RUN cat /etc/rocky-release | grep -Eo '[0-9]+(\.[0-9]+){0,}' > OS_VERSION

ENTRYPOINT [ "/bin/bash" ]

USER root

CMD ["-"]

