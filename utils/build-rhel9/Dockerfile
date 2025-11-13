###############################################################################################
# 
# Dockerfile for single container Hyrax
#
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

RUN export BUILD_DATE=`date +%s`
RUN echo "BUILD_DATE: ${BUILD_DATE}"


LABEL vendor="OPeNDAP"

MAINTAINER support@opendap.org

USER root

ARG DEVELOPER_MODE
ENV DEVELOPER_MODE=${DEVELOPER_MODE:-"false"}
RUN if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi


################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e && yum update  -y

# The things!
RUN set -e \
    && yum install -y procps git gcc-c++ flex bison cmake autoconf automake libtool emacs bzip2 vim bc \
    && yum install -y valgrind gdb unzip which jq diffutils \
    && yum install -y openssl-devel libuuid-devel readline-devel zlib-devel bzip2-devel \
    && yum install -y libjpeg-devel libxml2-devel curl-devel libicu-devel \
    && yum install -y java-21-openjdk java-21-openjdk-devel ant

RUN set -e  \
    && yum install -y openjpeg2-devel jasper-devel

RUN set -e  \
    && yum install -y cppunit cppunit-devel

# The libtirpc for 64 bit systems.
RUN set -e \
    && curl -O https://www.rpmfind.net/linux/centos-stream/9-stream/CRB/x86_64/os/Packages/libtirpc-devel-1.3.3-9.el9.i686.rpm \
    && curl -O https://www.rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/libtirpc-1.3.3-9.el9.i686.rpm \
    && yum install -y libtirpc-1.3.3-9.el9.i686.rpm  libtirpc-devel-1.3.3-9.el9.i686.rpm

RUN set -e \
    && yum install -y dnf-plugins-core install epel-release \
    && yum config-manager --set-enabled powertools \
    && yum install -y awscli2


RUN set -e \
    && yum install -y python3.12 \
    && python3 --version

RUN set -e \
    && curl -sS https://bootstrap.pypa.io/get-pip.py | python3 \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install --no-cache-dir awscli
#
RUN set -e \
    && yum clean all
RUN set -e \
    && which diff
#

RUN ls -l /usr/libexec/

ENTRYPOINT [ "/bin/bash" ]

USER root

CMD ["-"]

