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
FROM ubuntu:focal

LABEL vendor="OPeNDAP"
LABEL maintainer="support@opendap.org"

USER root

ENV HR="##########################################################################"
RUN set -e \
    && echo "$HR" \
    && echo "# Update and install packages..."

################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e && apt-get update  -y && apt-get -y upgrade

RUN set -e \
    && apt-get install -y  build-essential
RUN set -e && DEBIAN_FRONTEND=noninteractive apt-get install -y  uuid-dev pkg-config

RUN set -e && DEBIAN_FRONTEND=noninteractive apt-get install -y  libxml2 libxml2-dev

RUN set -e && apt-get install -y  libcurl4-openssl-dev libcurl4 libcppunit-dev libicu-dev sqlite3 libsqlite3-dev

RUN set -e \
    && apt-get install -y  libicu-dev  gcovr  libfl-dev openjdk-17-jdk-headless
RUN set -e \
    && apt-get install -y  grep emacs vim
RUN set -e \
    && apt-get install -y curl readline


RUN set -e \
    && echo "$HR" \
    && echo "# Installing zstd, via yum packages" \
    && echo "#" \
    && apt-get install -y zstd  zlib1g zlib1g-dev \
    && echo "#" \
    && echo "# zstd installed via apt-get packages" \
    && echo "$HR"

# The things!
RUN set -e \
RUN set -e    && apt-get install -y procps git gcc flex bison cmake autoconf automake libtool emacs bzip2 vim bc
RUN set -e    && apt-get install -y valgrind gdb unzip jq diffutils

RUN set -e    && apt-get install -y openssl libssl-dev
# RUN set -e    && apt-get install -y openssl-devel libuuid-devel readline-devel zlib-devel bzip2-devel

# RUN set -e    && apt-get install -y libjpeg-devel libxml2-devel libicu-devel
#
# RUN set -e    && apt-get install -y crypto

# RUN set -e    && apt-get install -y rpmdevtools rpmlint
# RUN set -e    && apt-get install -y java-21-openjdk java-21-openjdk-devel ant
RUN set -e    && apt-get clean all

#RUN set -e  \
#    && yum install -y openjpeg2-devel jasper-devel

#RUN set -e  \
#    && yum config-manager --set-enabled powertools \

#RUN set -e  \
#    && yum install -y cppunit cppunit-devel



RUN set -e \
    && apt-get install -y python3.12 \
    && python3 --version \
    && apt-get install -y awscli

RUN  set -e \
    && echo "# diff is here: $(which diff)" \
    && echo "$HR"

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

