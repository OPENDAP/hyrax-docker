###############################################################################################
# 
# Dockerfile for single container Hyrax
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
#
# RedHat host their own docker repo for our friend CentOS:
#   https://quay.io/repository/centos/centos
# Where one can go to get the stream8 and stream9 versions of CentOS docker
# images:
#   https://quay.io/repository/centos/centos?tag=stream8&tab=tags
#
# And so we use that for our FROM reference
FROM quay.io/centos/centos:stream8

# Only the first is used as of 2/8/22. jhrg
ARG HYRAX_VERSION="Not.A.Release-Docker"
# ARG OLFS_VERSION="default"
# ARG LIBDAP_VERSION="default"
# ARG BES_VERSION="default"

LABEL vendor="OPeNDAP"

MAINTAINER support@opendap.org

USER root

# See https://beenje.github.io/blog/posts/dockerfile-anti-patterns-and-best-practices/
# for information about running clean in the same RUN command as the other yum operations.
# jhrg 2/7/22

# 'Tricks' used in this file:
# Environment variables don't persist across RUN statements, so they have to be reset
# for each 'RUN' instruction/block.
# The documentation https://docs.docker.com/ engine/reference/builder/#environment-replacement)
# says that the ENV instruction is not supported by the RUN command, but later on, implies it
# is supported. I used "export ..." in the RUN instructions only because it makes what we're
# doing in each instruction easier to follow. There is some repeating of values, so I might
# coalesse those to ENV or ARG instuctions once this thing is working.
# To get the bash 'source' command to work, the script must be named, e.g., ./spath.sh

# Build up the packages for this image. This includes all the code needed to build
# hyrax. We use 'powertools' because it holds the tirpc library which we need for XDR (used
# by both hdf4 and libdap4).
#
# Packages in in alphabetical order with the command line ones first and then the libraries,
# with some wiggle room on 'libraries.'

RUN set -e \
    && yum config-manager --set-enabled powertools \
    && yum -y update \
    && yum -y install \
       ant \
       autoconf \
       automake \
       bc \
       bison \
       cmake \
       flex \
       gcc-c++ \
       git \
       libtool \
       python39 \
       rpm-build redhat-rpm-config rpm-devel \
       bzip2 bzip2-devel \
       cppunit cppunit-devel \
       curl-devel \
       jasper-devel \
       java-1.8.0-openjdk java-1.8.0-openjdk-devel \
       openjpeg2-devel \
       openssl-devel \
       libicu-devel \
       libjpeg-devel \
       libtirpc libtirpc-devel \
       libuuid-devel \
       libxml2-devel \
       readline-devel \
       sqlite-libs sqlite-devel \
       zlib-devel \
    && yum clean all \
    && pip3 install --user awscli

ENTRYPOINT [ "/bin/bash" ]


