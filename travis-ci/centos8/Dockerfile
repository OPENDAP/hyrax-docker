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
#
# RedHat host their own docker repo for our friend CentOS:
#   https://quay.io/repository/centos/centos
# Where one can go to get the stream8 and stream9 versions of CentOS docker
# images:
#   https://quay.io/repository/centos/centos?tag=stream8&tab=tags
#
# And so we use that for our FROM reference
FROM quay.io/centos/centos:stream8

# Maybe the CPPFLAGS adn LDFLAGS should go here? jhrg
ENV MAKE "make"

LABEL vendor="OPeNDAP Incorporated"

MAINTAINER support@opendap.org

USER root

# See https://beenje.github.io/blog/posts/dockerfile-anti-patterns-and-best-practices/
# for information about running clean in the same RUN command as the other yum operations.
# jhrg 2/7/22

# Build up the packages for this image. This includes all the code needed to build
# hyrax.

RUN set -e \
    && yum config-manager --set-enabled powertools \
    && yum -y update \
    && yum -y install \
       java-1.8.0-openjdk \
       java-1.8.0-openjdk-devel \
       ant \
       git \
       gcc-c++ \
       flex \
       bison \
       cmake \
       autoconf \
       automake \
       libtool \
       jasper-devel \
       openssl-devel \
       libuuid-devel \
       readline-devel \
       zlib-devel \
       bzip2 \
       bzip2-devel \
       libjpeg-devel \
       libxml2-devel \
       curl-devel \
       libicu-devel \
       cppunit \
       cppunit-devel \
       bc \
       openjpeg2-devel \
       libtirpc \
       libtirpc-devel \
       sqlite-libs \
       sqlite-devel \
       python39 \
    && yum clean all

# Now build the C++ parts of the server.
RUN set -e \
    && cd /home \
    && pwd \
    && git clone https://github.com/OPENDAP/hyrax \
    && cd hyrax \
    && pwd \
    && ls -l \
    && source ./spath.sh \
    && ./hyrax_clone.sh \
    && export CONFIGURE_FLAGS="--disable-shared" \
    && export CPPFLAGS=-I/usr/include/tirpc \
    && export LDFLAGS=-ltirpc \
    && cd hyrax-dependencies \
    && make -j16 ci-part-1 \
    && make -j16 ci-part-2 \
    && make -j16 ci-part-3 \
    && make -j16 ci-part-4 \
    && make list-built

ENTRYPOINT [ "/bin/bash" ]


