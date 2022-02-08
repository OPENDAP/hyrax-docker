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

# Now build dependencies. Note that CONFIGURE_FLAGS="--disable-shared" means
# the build will make only static libraries for the dependencies. That is
# good for the RPM pacakges NASA uses, but will result in a larger container
# if this is used for other purposes. jhrg 2/8/22
RUN set -e \
    && cd /home \
    && git clone https://github.com/OPENDAP/hyrax \
    && cd hyrax \
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

# Build libdap4. Build a production version of the library.
RUN set -e \
    && cd /home/hyrax \
    && pwd \
    && ls -l \
    && source ./spath.sh \
    && export CPPFLAGS=-I/usr/include/tirpc \
    && export LDFLAGS=-ltirpc \
    && cd libdap4 \
    && autoreconf --force --install --verbose \
    && ./configure --prefix=$prefix \
    && make -j16 \
    && make -j16 check 2>&1 | tee check.log \
    && make install \
    && make clean

# Build BES. Build a production version of the server.
RUN set -e \
    && cd /home/hyrax \
    && pwd \
    && ls -l \
    && source ./spath.sh \
    && export CPPFLAGS=-I/usr/include/tirpc \
    && export LDFLAGS=-ltirpc \
    && cd bes \
    && autoreconf --force --install --verbose \
    && ./configure --prefix=$prefix --with-dependencies=$prefix/deps \
    && make -j16 \
    && make -j16 check 2>&1 | tee check.log \
    && make install \
    && make clean

RUN set -e \
    && cd /home/hyrax \
    && pwd \
    && ls -l \
    && source ./spath.sh \
    && cd olfs \
    && ant server -DHYRAX_VERSION="Docker-1.16.5"

ENTRYPOINT [ "/bin/bash" ]


