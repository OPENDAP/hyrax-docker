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

ENV MAKE "make"

LABEL vendor="OPeNDAP Incorporated"

MAINTAINER support@opendap.org

USER root

#RUN set -e \
#    && dnf --disablerepo '*' --enablerepo=extras swap centos-linux-repos centos-stream-repos \
#    && dnf distro-sync

# See https://beenje.github.io/blog/posts/dockerfile-anti-patterns-and-best-practices/
# RUN set -e \
#     && yum clean all \
#    && yum -y update

# RUN set -e \
#    && yum config-manager --set-enabled powertools

RUN set -e \
    && yum config-manager --set-enabled powertools
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
       emacs \
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
       vim \
       bc \
       openjpeg2-devel \
       jasper-devel \
       libtirpc \
       libtirpc-devel \
       sqlite-libs \
       sqlite-devel \
    && yum clean all

# Above, we need both the libtirpc and it's -devel companion. Added sqlite-libs and -devel \
# for the gdal4 build on Stream8. jhrg 2/7/22

# RUN set -e \
#    && yum -y update \
#    && yum clean all

# The following may work when commands are all in one Dockerfile, but the env vars do not show up
# in the container when you run it. jhrg 2/7/22
# And the path should be /usr/include/tirpc and we may need to add /usr/include/tirpc/rpc as well.
#
RUN set -e \
    && export CPPFLAGS=-I/usr/include/tirpc \
    && export LDADD=-ltirpc

ENTRYPOINT [ "/bin/bash" ]


