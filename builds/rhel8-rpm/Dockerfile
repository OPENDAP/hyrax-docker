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
FROM rockylinux:8
# For a description of rockylinux:8. https://hub.docker.com/_/rockylinux
# Since this is updated monthly and/or if a critical issue is found, we
# skip the yum update step

LABEL vendor="OPeNDAP"

MAINTAINER support@opendap.org

USER root

################################################################
# Update and install the needful.
#

# To get the commands ps, which, etc.
RUN set -e && dnf install -y procps

# C++ environment plus build tools
RUN set -e && dnf install -y git gcc-c++ flex bison cmake autoconf automake libtool emacs bzip2 vim bc

# Development library versions
RUN set -e && dnf install -y openssl-devel libuuid-devel readline-devel zlib-devel bzip2-devel libjpeg-devel libxml2-devel curl-devel libicu-devel libtirpc-devel

# Java
RUN set -e && dnf install -y java-17-openjdk java-17-openjdk-devel ant

# Setup DNF so that we can load in some obscure packages from EPEL, etc., repos
RUN set -e && dnf install -y dnf-plugins-core
RUN set -e && dnf install -y epel-release
RUN set -e && dnf config-manager --set-enabled powertools

# Install CppUnit and some more development libraries
RUN set -e && dnf install -y cppunit cppunit-devel openjpeg2-devel jasper-devel

# Install the RPM tools
RUN set -e && dnf install -y rpm-devel rpm-build redhat-rpm-config

# Install the AWS CLI
RUN set -e && dnf install -y awscli

ENTRYPOINT [ "/bin/bash" ]
