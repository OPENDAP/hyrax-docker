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
FROM quay.io/centos/centos:stream8

ENV MAKE "make"

LABEL vendor="OPeNDAP Incorporated"

MAINTAINER support@opendap.org

USER root

#RUN set -e \
#    && dnf --disablerepo '*' --enablerepo=extras swap centos-linux-repos centos-stream-repos \
#    && dnf distro-sync

RUN set -e \
    && yum clean all \
    && yum -y update

RUN set -e \
    && yum config-manager --set-enabled powertools

RUN set -e \
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
       libtirpc-devel

#RUN set -e \
#    && yum -y install \
#        libicu-devel \
#        libicu

RUN set -e \
    && yum -y update \
    && yum clean all

RUN set -e \
    && export CPPFLAGS=-I/usr/include/tirpc \
    && export LDADD=-ltirpc

ENTRYPOINT [ "/bin/bash" ]


