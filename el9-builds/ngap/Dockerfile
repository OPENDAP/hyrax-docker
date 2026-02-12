#!/usr/bin/env bash
###############################################################################################
# 
# Dockerfile for the NGAP deployment Hyrax container
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
LABEL org.opencontainers.image.authors="support@opendap.org"
USER root
ENV HR="###############################################################################################################"
ENV HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
ENV TARGET_OS="el9"
ENV ARCH="x86_64"
ENV java_version="java-21-openjdk"
# rocky9 comes with python 3.9 by default.
ENV python_version="3.9"
RUN echo "$HR" && echo "# Python Version: $(python3 --version) (config says we want: $python_version)" && echo "$HR"

ENV core_dnf_packages="which unzip "

# The CRB (CodeReady Builder) repository has to be enabled to get the libtirpc-devel package.
ENV developer_dnf_packages="libtirpc libtirpc-devel libuuid libuuid-devel openssl openssl-devel"

#ENV developer_dnf_packages="procps diffutils curl unzip emacs vim jq procps git bc valgrind gdb"
ENV awscli_dnf_packages=""
#ENV awscli_dnf_packages="awscli"




# ENV DEPLOYMENT_CONTEXT="ROOT"
ENV DEFAULT_NGAP_DEPLOYMENT_CONTEXT="ngap"

ARG DEPLOYMENT_CONTEXT
ENV DEPLOYMENT_CONTEXT="${DEPLOYMENT_CONTEXT:-"ROOT"}"
RUN echo "# DEPLOYMENT_CONTEXT: $DEPLOYMENT_CONTEXT"

#
# Hyrax Components Version Negotiation
#
ARG RELEASE_DATE
ENV RELEASE_DATE="${RELEASE_DATE:-$(date +%s)}"
RUN echo "# RELEASE_DATE: $RELEASE_DATE"

ARG TOMCAT_VERSION
ENV TOMCAT_VERSION="${TOMCAT_VERSION:-"11.0.7"}"
RUN echo "# TOMCAT_VERSION: $TOMCAT_VERSION"

ENV TOMCAT_DISTRO="apache-tomcat-${TOMCAT_VERSION}"
COPY "${TOMCAT_DISTRO}.tar.gz" /
RUN ls -l /apache-tomcat-*  >&2

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "# HYRAX_VERSION: ${HYRAX_VERSION}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION="${LIBDAP_VERSION:-"snapshot"}"
RUN echo "# LIBDAP_VERSION: $LIBDAP_VERSION"

ARG LIBDAP_RPM
ENV LIBDAP_RPM="${LIBDAP_RPM:-"libdap-$LIBDAP_VERSION.$TARGET_OS.x86_64.rpm"}"
RUN echo "# LIBDAP_RPM: $LIBDAP_RPM"
COPY ${LIBDAP_RPM} libdap-devel-* libdap-debuginfo-* /
RUN ls -l /libdap-*  >&2

ARG BES_VERSION
ENV BES_VERSION="${BES_VERSION:-"snapshot"}"
RUN echo "# BES_VERSION: $BES_VERSION"

ARG BES_RPM
ENV BES_RPM="${BES_RPM:-"bes-$BES_VERSION.static.$TARGET_OS.x86_64.rpm"}"
RUN echo "# BES_RPM: $BES_RPM"
COPY "$BES_RPM" bes-devel-* bes-debuginfo-* /
RUN ls -l /bes-* >&2

ARG OLFS_VERSION
ENV OLFS_VERSION="${OLFS_VERSION:-"unknown"}"
RUN echo "# OLFS_VERSION: $OLFS_VERSION"

ARG REDIS_VERSION
ENV REDIS_VERSION="redisson-3.50.0"
RUN echo "# REDIS_VERSION: $REDIS_VERSION"

#ARG NGAP_DISTRO
# ENV NGAP_DISTRO="ngap-redisson-3.50.0-webapp"
# ENV NGAP_DISTRO=${NGAP_DISTRO:-"${REDIS_VERSION}-webapp"}
#ENV NGAP_DISTRO="${NGAP_DISTRO:-"ngap-$OLFS_VERSION-webapp"}"
#RUN echo "NGAP_DISTRO: ${NGAP_DISTRO}"
#COPY ${NGAP_DISTRO}.tgz /
#COPY "${NGAP_DISTRO}.tgz" /${NGAP_DISTRO}.tgz
#RUN tar -tf /${NGAP_DISTRO}.tgz

ARG NGAP_DISTRO
ENV NGAP_DISTRO=${NGAP_DISTRO:-"ngap-${OLFS_VERSION}-webapp"}
RUN echo "# NGAP_DISTRO: ${NGAP_DISTRO}"
COPY ${NGAP_DISTRO}.tgz /${NGAP_DISTRO}.tgz


#ARG OPENSSL_VERSION
#ENV OPENSSL_RPM="openssl-$OPENSSL_VERSION.$TARGET_OS.x86_64.rpm"
#RUN echo "#       OPENSSL_RPM: $OPENSSL_RPM"
#COPY "$OPENSSL_RPM" /
#ENV OPENSSL_LIBS_RPM="openssl-libs-$OPENSSL_VERSION.$TARGET_OS.x86_64.rpm"
#RUN echo "#  OPENSSL_LIBS_RPM: $OPENSSL_LIBS_RPM"
#COPY "$OPENSSL_LIBS_RPM" /
#ENV OPENSSL_DEVEL_RPM="openssl-devel-$OPENSSL_VERSION.$TARGET_OS.x86_64.rpm"
#RUN echo "# OPENSSL_DEVEL_RPM: $OPENSSL_DEVEL_RPM"
#COPY "$OPENSSL_DEVEL_RPM" /
#RUN ls -l /openssl-* >&2

ARG APR_VERSION
ENV APR_VERSION="1.7.6-1"
RUN echo "# Apache APR version: $APR_VERSION"

ARG APACHE_APR_RPM
ENV APACHE_APR_RPM="${APACHE_APR_RPM:-"apr-$APR_VERSION.x86_64.rpm"}"
RUN echo "# APACHE_APR_RPM: $APACHE_APR_RPM"
COPY "$APACHE_APR_RPM" apr-devel-* apr-debuginfo-* /
RUN ls -l /apr-* >&2

ARG TOMCAT_CONNECTION_TIMEOUT_MS
ENV TOMCAT_CONNECTION_TIMEOUT_MS="${TOMCAT_CONNECTION_TIMEOUT_MS:-"1000000"}"
RUN echo "# TOMCAT_CONNECTION_TIMEOUT_MS: $TOMCAT_CONNECTION_TIMEOUT_MS"

LABEL vendor="OPeNDAP"
LABEL org.opendap.hyrax.version=${HYRAX_VERSION}
LABEL org.opendap.hyrax.release-date=${RELEASE_DATE}
LABEL org.opendap.hyrax.version.is-production="false"
LABEL org.opencontainers.image.authors="support@opendap.org"

USER root

ARG DEVELOPER_MODE
ENV DEVELOPER_MODE="${DEVELOPER_MODE:-"false"}"
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "# DEVELOPER_MODE: ENABLED"; else echo "# DEVELOPER_MODE: DISABLED"; fi

################################################################
# Update and install the needful.
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e \
    && dnf update  -y \
    && dnf clean all

#RUN set -e && dnf install -y dnf-plugins-core \
#    && dnf config-manager --set-enabled crb \
#    && dnf groupinstall "Development Tools" -y

RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Installing cURL" >&2 \
    && dnf install -y curl curl-devel --allowerasing \
    && echo "# cURL version: $(curl --version)" >&2 \
    && dnf clean all \
    && echo "$HR" >&2

RUN set -e \
    && echo "$HR" >&2 \
    && echo "# It's Java Time Witches!" >&2 \
    && echo "# Installing $java_version" >&2 \
 #    && dnf install -y "$java_version" "$java_version-devel"  \
    && dnf install -y "$java_version" "$java_version-devel" \
    && echo "$HR2" >&2 \
    && echo "# Using $java_version" >&2 \
    && update-alternatives --set java "$java_version.$ARCH" \
    && echo "# Enabled $java_version" >&2 \
    && echo "# java version: $( java -version 2>&1 )" \
    && update-alternatives --list \
#    && dnf install -y tzdata-java \
    && dnf clean all \
    && echo "$HR" >&2

RUN set -e \
    && echo "$HR" >&2 \
    # The CRB (CodeReady Builder) repository has to be enabled to get the libtirpc-devel package.
    && echo "# Installing 'dnf-plugins-core', enabling CRB (CodeReady Builder) repository and installing 'Development Tools'" >&2 \
    && dnf install -y dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf groupinstall "Development Tools" -y \
    && echo "$HR2" >&2 \
    && echo "# Installing dnf packages..." >&2 \
    # && dnf info  $core_dnf_packages $developer_dnf_packages $awscli_dnf_packages \
    && dnf install -y $core_dnf_packages $developer_dnf_packages $awscli_dnf_packages \
    && dnf clean all \
    && echo "$HR" >&2

# The follow is a sanity check so that we can see what we got.
RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Sanity checking installed packages..." >&2 \
    && echo "# openssl is located here: $(which openssl)" >&2 \
    && echo "# openssl version: $(openssl version)" >&2 \
    && dnf -y info openssl >&2 \
    #&& rm -vf ./openssl*
    && echo "# openssl is installed." >&2 \
    && echo "$HR" >&2 \
    && echo "# libtirpc info:" >&2 \
    && dnf -y info libtirpc >&2 \
    && echo "$HR2" >&2 \
    && echo "# rpm -ql libtirpc: " >&2 \
    && rpm -ql libtirpc  >&2 \
    && echo "$HR" >&2 \
    && echo "# libtirpc-devel info:" >&2 \
    && dnf -y info libtirpc-devel >&2 \
    && echo "$HR2" >&2 \
    && echo "# rpm -ql libtirpc-devel: " >&2 \
    && rpm -ql libtirpc-devel >&2 \
    && echo "$HR" >&2 \
    && echo "# libuuid info:" >&2 \
    && dnf -y info libuuid >&2 \
    && echo "# libuuid-devel info:" >&2 \
    && dnf -y info libuuid-devel >&2 \
    && dnf clean all \
    && echo "$HR" >&2


#RUN set -e && dnf install -y make curl unzip which autoconf automake emacs vim jq \
#    && dnf install -y libtirpc libtirpc-devel \
#    && dnf install -y libuuid libuuid-devel \
#    && dnf install -y jq \
#    && dnf install -y diffutils \
#    && dnf install -y procps \
#    && dnf install -y git bc valgrind gdb \
#    && dnf install -y java-17-openjdk-devel \
#    && dnf install -y redhat-rpm-config
#    && dnf install -y openssl-devel

################################################################
# Install the latest libdap snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Installing the libdap rpm: ${LIBDAP_RPM}" >&2 \
    && ls -l ./libdap* \
    && dnf -y install ./libdap-*.rpm \
    && echo "# The 'dnf install' command exited with status: $?" >&2 \
    && rm -f "./$LIBDAP_RPM" \
    && dnf clean all \
    && echo "# libdap4 is installed." >&2 \
    && echo "$HR" >&2

################################################################
# Install the latest BES snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Installing the BES rpm: $BES_RPM" >&2 \
    && ls -l ./bes* \
    && dnf -y install ./bes-*.rpm \
    && echo "# The 'dnf install' command exited with status: $?" >&2 \
    && rm -f "./$BES_RPM" \
    && dnf clean all \
    && echo "# besdaemon is here: $(which besdaemon)" >&2 \
    && echo "#      besdaemon -v: '$(besdaemon -v)'" >&2 \
    && echo "$HR" >&2


################################################################
# Install the Apache-Portable-Runtime (Apache APR)
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "$HR" >&2 \
    && echo "Installing the Apache APR rpm: ${APACHE_APR_RPM}" >&2 \
    && ls -l ./apr*  >&2\
    && dnf -y install ./apr-*.rpm  >&2\
    && echo "# The 'dnf install' command exited with status: $?" >&2 \
    && dnf list installed | grep apr >&2 \
    && rm -f "./$APACHE_APR_RPM" \
    && dnf clean all \
    && echo "Apache APR is installed." >&2 \
    && echo "$HR" >&2
################################################################
# Install and Setup Tomcat
#
# Make tomcat user and group
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e && useradd -m -U -d /home/tomcat -s /bin/false tomcat
#
# Install the Tomcat package that should have been copied into
# the root directory prior to this layer.
#
RUN set -e \
    && echo "$HR" >&2 \
    && df -h >&2 \
    && echo "$HR" >&2 \
    && echo "# Unpacking Tomcat distribution: $TOMCAT_DISTRO.tar.gz" >&2 \
    && tar -xvf "/$TOMCAT_DISTRO.tar.gz" -C "/home/tomcat" >&2 \
    && echo "# Distribution unpacked. Linking to /usr/share/tomcat" >&2 \
    && echo "# $(ln -vs "/home/tomcat/$TOMCAT_DISTRO" "/usr/share/tomcat")" >&2 \
    && echo "# Cleaning webapps dir" >&2 \
    && rm -rf /usr/share/tomcat/webapps/* >&2 \
    && echo "# Setting up logs" >&2 \
    && mkdir -p /var/log/tomcat \
    && chown -R tomcat:tomcat /var/log/tomcat /home/tomcat \
    && echo "# Tomcat is unpacked and ready. >&2 "
COPY tomcat.service /etc/systemd/system/tomcat.service
RUN set -e \
    && echo "$HR2" >&2 \
    && echo "# Calling: 'systemctl enable tomcat'" >&2 \
    && echo "# $(systemctl enable tomcat)" >&2 \
    && echo "# systemctl status: $?" >&2 \
    && echo "$HR" >&2
#RUN firewall-cmd --add-port 8080/tcp --permanent
#RUN firewall-cmd --reload

ENV CATALINA_HOME="/usr/share/tomcat"
ENV PATH="$CATALINA_HOME/bin:$PATH"
RUN set -e && echo "# CATALINA_HOME: $CATALINA_HOME" >&2

# Install our modified server.xml so that the server compresses responses.
COPY tomcat11-server.xml /
RUN set -e \
    && mv "/tomcat11-server.xml" "$CATALINA_HOME/conf/server.xml" \
    && chown -R tomcat:tomcat "$CATALINA_HOME/conf/server.xml"

RUN set -e \
    && echo "Cleaning up Tomcat distribution files..." >&2 \
    && rm -fv "/$TOMCAT_DISTRO.tar.gz"  >&2

###########################################################################################
#
# Build and Install the Tomcat Native-APR library.
# @TODO This building should be done elsewhere and brought in
#
RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Installing Tomcat Native APR" >&2 \
    && export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which javac))))" >&2 \
    && echo "# JAVA_HOME: $JAVA_HOME" >&2 \
    && echo "$HR2" >&2 \
    && ls -l "$CATALINA_HOME/bin" >&2 \
    && echo "$HR2" >&2 \
    && tar -xf "/$CATALINA_HOME/bin/tomcat-native.tar.gz" -C "$CATALINA_HOME/bin" >&2 \
    && echo "$HR2" >&2 \
#    && ls -l ${CATALINA_HOME}/bin/tomcat-native-*-src >&2 \
    && cd $CATALINA_HOME/bin/tomcat-native-*-src/native >&2 \
    && ./configure --with-apr=/usr/bin >&2 \
    && echo "$HR2" >&2 \
    && make >&2 \
    && echo "$HR2" >&2 \
    && make install >&2 \
    && echo "$HR2" >&2 \
    && echo "# SUCCESS: Tomcat Native-APR Library installed." >&2 \
    && echo "$HR" >&2

ENV CATALINA_OPTS="-Djava.library.path=/usr/local/apr/lib"

RUN set -e \
    && echo "$HR" >&2 \
    && echo "# The java executable is here: $(which java)" >&2 \
    && echo "# Using java version: $( java -version 2>&1 )" >&2 \
    && echo "$HR" >&2

################################################################
# Retrieve, verify, and install the NGAP/OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

# NGAP package uses the OLFS_VERSION number. jhrg 4/2/21
RUN set -e \
    && echo "$HR" \
    && echo "Installing the latest NGAP distribution ($NGAP_DISTRO)." >&2 \
    && echo "working dir: "$(pwd)"    ROOT: $ROOT"  >&2 \
    && tar -C "$ROOT" -xzvf "/$NGAP_DISTRO.tgz" >&2 \
    && ls -l "$ROOT" >&2 \
    && echo "Unpacking war file..." >&2 \
    && unzip -o "$ROOT/$NGAP_DISTRO/$DEFAULT_NGAP_DEPLOYMENT_CONTEXT.war" -d "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT/" \
    && echo "Cleaning up." >&2 \
    && rm -rf "$ROOT/$NGAP_DISTRO" "/$NGAP_DISTRO.tgz" \
    && echo "$HR" >&2

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT/WEB-INF/conf/logs" \
    && chown -R tomcat:tomcat "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT/WEB-INF/conf/logs" \
    && chmod 700 "$CATALINA_HOME/webapps/$DEPLOYMENT_CONTEXT/WEB-INF/conf/logs"
################################################################

################################################################
# Install our modified tomcat.conf so that the server use the memory
# cached session state and not require sticky sessions to operate
# behind a load balancer.
#
COPY tomcat.conf /
RUN set -e \
    && mkdir -p /etc/tomcat \
    && mv /tomcat.conf /etc/tomcat/tomcat.conf \
    && chown -R tomcat:tomcat /etc/tomcat

#
# Request Redisson and Apache Session Level logging in the logging.properties
RUN set -e \
    && echo "org.redisson.level = FINE" >> "$CATALINA_HOME/conf/logging.properties" \
    && echo "org.apache.catalina.core.level = FINE" >> "$CATALINA_HOME/conf/logging.properties" \
    && echo "org.apache.catalina.session.level = FINE" >> "$CATALINA_HOME/conf/logging.properties"
#
# Install Memcached Session Manager jars into the Tomcat: ${CATALINA_HOME}/lib
RUN set -e \
    && echo "$HR" >&2 \
    && echo "Installing Session Manager jar files. Cloning OLFS..." >&2 \
    && git clone https://github.com/OPENDAP/olfs \
    #&& git clone --depth 1 https://github.com/OPENDAP/olfs \
    && cd olfs \
    && git checkout tomcat-11 \
    && cd .. \
    && echo "$HR2" >&2 \
    && echo "Copying elasticache client" >&2 \
    && cp -v "olfs/resources/ngap/lib/elasticache-java-cluster-client-1.1.2.jar" "$CATALINA_HOME/lib" \
    && echo "Copying redisson all" >&2 \
    && cp -v "olfs/resources/ngap/lib/redisson-all-3.50.0.jar" "$CATALINA_HOME/lib" \
    && echo "Copying redisson Session Manager TC11" >&2 \
    && cp -v "olfs/resources/ngap/lib/redisson-tomcat-11-3.50.0.jar" "$CATALINA_HOME/lib" \
    && chown -R tomcat:tomcat "$CATALINA_HOME/lib" \
    && rm -rfv olfs \
    && echo "$HR" >&2

################################################################
#
# Retrieve, verify, and install the hyrax_regression_tests
# project
#
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV TEST_INSTALL_DIR="/hyrax_regression_tests"
RUN set -e \
    && echo "$HR" >&2 \
    && echo "Retrieving, and building hyrax regression tests." >&2 \
    && echo "h_r_t will be in: $TEST_INSTALL_DIR" >&2 \
    && mkdir -p "$TEST_INSTALL_DIR" \
    && git clone -v "https://github.com/opendap/hyrax_regression_tests" "$TEST_INSTALL_DIR" \
    && cd "$TEST_INSTALL_DIR" \
    && git status >&2 \
    && autoreconf -vif >&2 \
    && ./configure >&2 \
    && make testsuite > mk.log 2>&1 \
    && echo "SUCCESS: hyrax_regression_tests ready!" >&2 \
    && echo "$HR" >&2

################################################################
# TEMPORARY
# Grab the cleanup files script for managing orphaned files
# from fileout_netcdf
COPY cleanup_files.sh /
RUN chmod +x /cleanup_files.sh
# TEMPORARY
################################################################

COPY entrypoint.sh /
RUN  set -e && chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN  set -e && chown -R bes /etc/bes
USER root

CMD ["-"]

