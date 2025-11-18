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

LABEL vendor="OPeNDAP"
LABEL maintainer="support@opendap.org"

USER root

ENV HR="################################################################"
RUN set -e && echo "${HR}"
RUN set -e && echo "# Update and install packages..."

################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e && yum update  -y

RUN set -e \
    && dnf install -y 'dnf-command(config-manager)'

# Enable crb so we can get the libtirpc and libtirpc-devel
RUN set -e \
    && dnf config-manager --set-enabled "crb"

# Set up our friends dnf-plugins-code, epel, and codeready-builder-for-rhel-9
RUN set -e \
    && dnf install -y dnf-plugins-core epel-release

# The things!
RUN set -e \
    && yum install -y libtirpc  libtirpc-devel \
    && yum install -y procps git gcc-c++ flex bison cmake autoconf271 automake libtool emacs bzip2 vim bc \
    && yum install -y valgrind gdb unzip which jq diffutils \
    && yum install -y openssl-devel libuuid-devel readline-devel zlib-devel bzip2-devel \
    && yum install -y libjpeg-devel libxml2-devel curl-devel libicu-devel \
    && yum install -y rpmdevtools rpmlint \
    && yum install -y java-21-openjdk java-21-openjdk-devel ant \
    && yum clean all

#RUN set -e  \
#    && yum install -y openjpeg2-devel jasper-devel

#RUN set -e  \
#    && yum config-manager --set-enabled powertools \

#RUN set -e  \
#    && yum install -y cppunit cppunit-devel



RUN set -e \
    && yum install -y python3.12 \
    && python3 --version \
    && yum install -y awscli2

RUN  echo "# diff is here: $(which diff)" \
    && echo "$HR"

# We need to make sure there is a directory/mount_point for the calling process
# to mount a volume that will receieve the RPM files.
RUN set -e \
    && echo "I AM THE USER $(whoami)" \
    && mkdir -vp "/root/rpmbuild" \
    && echo "HOME: $HOME" \
    && echo "~: "~

# RUN ls -l /usr/libexec/

RUN export BUILD_DATE=`date +%s`
RUN echo "BUILD_DATE: ${BUILD_DATE}"

ENTRYPOINT [ "/bin/bash" ]

USER root

CMD ["-"]

