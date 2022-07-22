#!/usr/bin/env bash
###############################################################################################
# 
# Dockerfile for the NGAP deployment Hyrax container
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
FROM centos:7

# HYRAX VERSION INFO
ENV HYRAX_VERSION=HYRAX_MAJOR_VERSION_TEMPLATE
ENV HYRAX_VERSION_LABEL=HYRAX_FULL_VERSION_TEMPLATE
ENV LIBDAP_VERSION=LIBDAP_VERSION_TEMPLATE
ENV BES_VERSION=BES_VERSION_TEMPLATE
ENV OLFS_VERSION=OLFS_VERSION_TEMPLATE
ENV RELEASE_DATE=RELEASE_DATE_TEMPLATE

# ENV DEPLOYMENT_CONTEXT="ROOT"
ENV DEFAULT_NGAP_DEPLOYMENT_CONTEXT="ngap"

ARG DEPLOYMENT_CONTEXT
ENV DEPLOYMENT_CONTEXT ${DEPLOYMENT_CONTEXT:-"ROOT"}
RUN echo "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"


RUN export NOW=`date +%s`
# HYRAX VERSION INFO
ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"


LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.hyrax.version=snapshot
LABEL org.opendap.hyrax.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

ARG DEVELOPER_MODE
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"false"}
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi


################################################################
# Update and install the needful.
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# howerver, to be run, so install them as part of this Dockerfile.
RUN set -e \
    && yum -y install tomcat unzip which python3 autoconf automake git bc emacs vim \
    && yum -y update \
    && yum clean all \
    && python3 -m pip install awscli

################################################################
# Tomcat environment (Tomcat installed above by via yum)
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

################################################################
# Install the OPeNDAP security public key.
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
# TODO: We should get this from a well known key-server instead.
RUN echo "Adding OPeNDAP Public Security Key"
ENV OPENDAP_PUBLIC_KEY_FILE="security_at_opendap.org.pub.asc"
ENV OPENDAP_PUBLIC_KEY_URL="https://www.opendap.org/${OPENDAP_PUBLIC_KEY_FILE}"
RUN set -e \
    && curl -s $OPENDAP_PUBLIC_KEY_URL > $OPENDAP_PUBLIC_KEY_FILE \
    && gpg --import $OPENDAP_PUBLIC_KEY_FILE
###############################################################


###############################################################
# RELEASE URLs
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV LIBDAP_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/centos-7.x/libdap-${LIBDAP_VERSION}.el7.x86_64.rpm"
ENV BES_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/centos-7.x/bes-${BES_VERSION}.static.el7.x86_64.rpm"
ENV NGAP_PACKAGE="https://www.opendap.org/pub/olfs/ngap-${HYRAX_VERSION_LABEL}-webapp.tgz"
###############################################################


###############################################################
# Retrieve, verify, and install Libdap
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving, verifying, and installing libdap. rpm: $LIBDAP_RPM" \
    && curl -s $LIBDAP_RPM > ./libdap.rpm \
    && curl -s $LIBDAP_RPM.sig > ./libdap.rpm.sig \
    && gpg -v --verify ./libdap.rpm.sig ./libdap.rpm \
    && ls -l ./libdap* \
    && yum -y install ./libdap.rpm \
    && rm -f libdap.*

# gpg --keyserver certserver.pgp.com --recv-keys
###############################################################


###############################################################
# Retrieve, verify, and install the BES
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving, verifying, and installing besd. rpm: $BES_RPM" \
    && curl -s ${BES_RPM} > ./bes.rpm \
    && curl -s ${BES_RPM}.sig > ./bes.rpm.sig \
    && gpg -v --verify ./bes.rpm.sig ./bes.rpm \
    && ls -l ./bes* \
    && yum -y install ./bes.rpm \
    && rm -f bes.*

RUN echo "besdaemon is here: "`which besdaemon`
###############################################################



################################################################
# Retrieve, verify, and install the NGAP web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving, verifying, and installing NGAP package: ${NGAP_PACKAGE}" \
    && curl -sfSL ${NGAP_PACKAGE} > ngap-${HYRAX_VERSION_LABEL}.tgz \
    && curl -sfSL ${NGAP_PACKAGE}.sig > ngap-${HYRAX_VERSION_LABEL}.tgz.sig \
    && echo "Verifying tarball..." \
    && gpg --verify ngap-${HYRAX_VERSION_LABEL}.tgz.sig ngap-${HYRAX_VERSION_LABEL}.tgz \
    && echo "Unpacking tarball..." \
    && tar -C /dev/shm -xzf ngap-${HYRAX_VERSION_LABEL}.tgz \
    && echo "Unpacking warfile..." \
    && unzip -o /dev/shm/ngap-${HYRAX_VERSION_LABEL}-webapp/${DEFAULT_NGAP_DEPLOYMENT_CONTEXT}.war -d ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/ \
    && echo "Cleaning up." \
    && rm -rf /dev/shm/* ngap-${HYRAX_VERSION_LABEL}.tgz*
#
#
# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs
################################################################



################################################################
# Install our modified server.xml so that the server compresses responses and
# sets the connectionTimeout to 1000 seconds
COPY tomcat7-server.xml /
RUN set -e \
    && mv /tomcat7-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml
################################################################

################################################################
# Install our modified tomcat.conf so that the server use the memory.
COPY tomcat.conf /
RUN set -e \
    && mv /tomcat.conf /etc/tomcat/tomcat.conf \
    && chown -R tomcat:tomcat /etc/tomcat/tomcat.conf

# Install Session Manager jars into the Tomcat: ${CATALINA_HOME}/lib
RUN set -e \
    && echo "Installing Session Manager jar files. Cloning OLFS..." \
    && git clone --depth 1 https://github.com/OPENDAP/olfs \
    && echo "Copying elasticache client" \
    && cp olfs/resources/ngap/lib/elasticache-java-cluster-client-1.1.2.jar ${CATALINA_HOME}/lib \
    && echo "Copying memcached Session Manager" \
    && cp olfs/resources/ngap/lib/memcached-session-manager-2.3.2.jar ${CATALINA_HOME}/lib \
    && echo "Copying memcached Session Manager TC7" \
    && cp olfs/resources/ngap/lib/memcached-session-manager-tc7-2.3.2.jar ${CATALINA_HOME}/lib \
    && chown -R tomcat:tomcat  ${CATALINA_HOME}/lib \
    && rm -rfv olfs

RUN yum clean all
################################################################

################################################################
#
# Retrieve, verify, and install the hyrax_regression_tests
# project
#
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV TEST_INSTALL_DIR="/hyrax_regression_tests"
RUN set -e \
    && echo "Retrieving, and building hyrax regression tests." \
    && echo "h_r_t will be in: ${TEST_INSTALL_DIR}" \
    && mkdir -p ${TEST_INSTALL_DIR} \
    && git clone -v https://github.com/opendap/hyrax_regression_tests ${TEST_INSTALL_DIR} \
    && cd ${TEST_INSTALL_DIR} \
    && git checkout tags/hyrax-${HYRAX_VERSION_LABEL} \
    && git status \
    && autoreconf -vif \
    && ./configure


# In order to get the executable "testsuite" to build we have to run
# "make check" But that will fail at build time so the "make check" call
# ends up pretty tortured to avoid a build error.
RUN set -e \
    && cd ${TEST_INSTALL_DIR} \
    && make testsuite > mk.log 2>&1 \
    && echo "SUCCESS: hyrax_regression_tests ready!"

COPY beslog2json.awk /
RUN  set -e && chmod +x beslog2json.awk

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

