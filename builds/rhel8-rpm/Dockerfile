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

FROM rockylinux:8
# For a description of rockylinux:8. https://hub.docker.com/_/rockylinux
# Since this is updated monthly and/or if a critical issue is found, we
# skip the yum update step

# FROM redhat/ubi8
# 'ubi' == Universal Base Image. About: https://hub.docker.com/r/redhat/ubi8
#
# While this is a good idea, some pacakges don't seem to be available by default and
# when I try to add repos to DNF, I get:
#
# Updating Subscription Management repositories.
# Unable to read consumer identity
# This system is not registered with an entitlement server. You can use subscription-manager to register.

LABEL vendor="OPeNDAP"

MAINTAINER support@opendap.org

USER root

################################################################
# Update and install the needful.
#

# To get the commands ps, which, etc.
RUN set -e && dnf install -y procps

# C++ environment plus build tools,  Development library versions, and Java 17
RUN set -e && dnf install -y git gcc-c++ flex bison cmake autoconf automake libtool emacs bzip2 vim bc \
&& dnf install -y openssl-devel libuuid-devel readline-devel zlib-devel bzip2-devel libjpeg-devel \
&& dnf install -y libxml2-devel curl-devel libicu-devel libtirpc-devel \
&& dnf install -y java-17-openjdk java-17-openjdk-devel ant

# Setup DNF so that we can load in some obscure packages from EPEL, etc., repos
RUN set -e && dnf install -y dnf-plugins-core \
&& dnf install -y epel-release \
&& dnf config-manager --set-enabled powertools

# Install CppUnit and some more development libraries, RPM tools, and the AWS CLI
RUN set -e && dnf install -y cppunit cppunit-devel openjpeg2-devel jasper-devel \
&& dnf install -y rpm-devel rpm-build redhat-rpm-config \
&& dnf install -y awscli

ENTRYPOINT [ "/bin/bash" ]
