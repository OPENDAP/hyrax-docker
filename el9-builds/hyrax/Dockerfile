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
FROM rockylinux:9
ENV TARGET_OS="el9"
ENV ARCH="x86_64"
ENV java_version="java-21-openjdk"
# rocky9 comes with python 3.9 by default.
ENV python_version="3.9"
RUN echo "Python Version: $(python3 --version) (config says we want: $python_version)"
ENV core_dnf_packages="make autoconf automake procps git unzip "
#ENV extra_dnf_packages="which diffutils emacs vim jq  procps git bc valgrind gdb awscli"
ENV extra_dnf_packages=""

#
ENV HR="######################################################"

ENV NOW="$(date +%s)"
ARG RELEASE_DATE
ENV RELEASE_DATE=${RELEASE_DATE:-"${NOW}"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG TOMCAT_VERSION
ENV TOMCAT_VERSION=${TOMCAT_VERSION:-"11.0.7"}
RUN echo "TOMCAT_VERSION: ${TOMCAT_VERSION}"
ENV TOMCAT_DISTRO="apache-tomcat-${TOMCAT_VERSION}"
COPY "${TOMCAT_DISTRO}.tar.gz" /
RUN ls -l /apache-tomcat-*  >&2

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"libdap-${LIBDAP_VERSION}.${TARGET_OS}.x86_64.rpm"}
RUN echo "LIBDAP_RPM: ${LIBDAP_RPM}"
COPY ${LIBDAP_RPM} libdap-devel-* libdap-debuginfo-* /
RUN ls -l /libdap-*  >&2

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"bes-${BES_VERSION}.static.${TARGET_OS}.x86_64.rpm"}
RUN echo "BES_RPM: ${BES_RPM}"
COPY ${BES_RPM} bes-devel-* bes-debuginfo-* /
RUN ls -l /bes-* >&2

ARG OLFS_VERSION
ENV OLFS_VERSION=${OLFS_VERSION:-"snapshot-${TARGET_OS}"}
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

ARG OLFS_DISTRO
ENV OLFS_DISTRO=${OLFS_DISTRO:-"olfs-${OLFS_VERSION}-webapp"}
RUN echo "OLFS_DISTRO: ${OLFS_DISTRO}"
COPY ${OLFS_DISTRO}.tgz /${OLFS_DISTRO}.tgz

ARG ROBOTS_DISTRO
ENV ROBOTS_DISTRO=${ROBOTS_DISTRO:-"robots-olfs-${OLFS_VERSION}-webapp"}
RUN echo "ROBOTS_DISTRO: ${ROBOTS_DISTRO}"
COPY ${ROBOTS_DISTRO}.tgz /${ROBOTS_DISTRO}.tgz

ARG DEPLOYMENT_CONTEXT
ENV DEPLOYMENT_CONTEXT=${DEPLOYMENT_CONTEXT:-"opendap"}
RUN echo "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"

LABEL vendor="OPeNDAP"
LABEL org.opendap.hyrax.version=${HYRAX_VERSION}
LABEL org.opendap.hyrax.release-date=${RELEASE_DATE}
LABEL org.opendap.hyrax.version.is-production="false"
LABEL org.opencontainers.image.authors="support@opendap.org"

USER root

#
# The --build-arg USE_NCWMS can be set to "true" in order to 
# add the ncWMS application to the build.
ARG USE_NCWMS
ENV USE_NCWMS=${USE_NCWMS:-"false"}
RUN if [ $USE_NCWMS = "true" ];then echo "NCWMS: ENABLED"; else echo "NCWMS: DISABLED"; fi

#
# The --build-arg NCWMS_BASE can be set to the base URL for ncWMS.
# The entrypoint.sh code defaults it to
# the URL: https://localhost:8080 if the environment variable NCWMS_BASE
# is not in the shell from which the entrypoint.sh script is called.
ARG NCWMS_BASE
ENV NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
RUN if [ $USE_NCWMS = "true" ];then echo "NCWMS_BASE: {$NCWMS_BASE}"; fi


ARG DEVELOPER_MODE
ENV DEVELOPER_MODE=${DEVELOPER_MODE:-"false"}
RUN if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi

#Get mirrorlist before running yum
#RUN cd /etc/yum.repos.d/
#RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e && dnf update  -y

RUN set -e \
    && dnf install -y "python$python_version" \
    && echo "Python Version: $(python3 --version)" \
    && dnf clean all
RUN set -e \
    && echo "$HR" \
    && echo "# Installing cURL" \
    && yum install -y curl curl-devel --allowerasing \
    && echo "# cURL version: $(curl --version)" \
    && dnf clean all
RUN set -e \
    && echo "$HR" \
    && echo "# It's Java Time Witches!" \
    && echo "# Installing $java_version" \
    && yum install -y "$java_version" "$java_version-devel"  \
    && echo "$HR2" \
    && echo "# Using $java_version" \
    && update-alternatives --set java "$java_version.$ARCH" \
    && echo "# Enabled $java_version" \
    && echo "# java version: $( java -version 2>&1 )" \
    && update-alternatives --list \
    && dnf install -y tzdata-java \
    && dnf clean all
RUN set -e \
    && dnf install -y $core_dnf_packages $extra_dnf_packages \
    && dnf clean all
#
# RUN set -e && which diff
#



################################################################
# Install the latest libdap snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the libdap rpm: ${LIBDAP_RPM}" \
    && ls -l ./libdap* \
    && dnf -y install ./libdap-*.rpm \
    && rm -f ./${LIBDAP_RPM} \
    && dnf clean all \
    && echo "libdap4 is installed."

################################################################
# Install the latest BES snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the latest BES rpm: ${BES_RPM}" \
    && ls -l ./bes* \
    && dnf -y install ./bes-*.rpm \
    && rm -f ./${BES_RPM} \
    && dnf clean all \
    && echo "besdaemon is here: "`which besdaemon`

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
    && tar -xvf "/${TOMCAT_DISTRO}.tar.gz" -C /home/tomcat >&2 \
    && ln -s /home/tomcat/${TOMCAT_DISTRO} /usr/share/tomcat >&2 \
    && ln -s /home/tomcat/${TOMCAT_DISTRO} /tomcat >&2 \
    && rm -rvf /usr/share/tomcat/webapps/* >&2 \
    && mkdir -p /var/log/tomcat \
    && chown -R tomcat:tomcat /var/log/tomcat /home/tomcat \
    && echo "Cleaning up Tomcat distribution files..." >&2 \
    && rm -fv "/${TOMCAT_DISTRO}.tar.gz"

COPY tomcat.service /etc/systemd/system/tomcat.service
RUN set -e && systemctl enable tomcat
#RUN firewall-cmd --add-port 8080/tcp --permanent
#RUN firewall-cmd --reload

ENV CATALINA_HOME=/usr/share/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH
RUN set -e && echo "CATALINA_HOME: ${CATALINA_HOME}" >&2

# Install our modified server.xml so that the server compresses responses.
COPY tomcat11-server.xml /
RUN set -e \
    && mv /tomcat11-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml


################################################################
# Install the OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

RUN echo "Installing the latest olfs distribution (${OLFS_VERSION})." >&2
RUN set -e \
    && echo "working_dir: "`pwd`  >&2 \
    && ls -l . \
    && tar -C ${ROOT} -xzvf ./${OLFS_DISTRO}.tgz \
    && ls -l ${ROOT} \
    && echo "Unpacking warfile..."  >&2 \
    && mkdir -p $(readlink -f ${CATALINA_HOME})/webapps/${DEPLOYMENT_CONTEXT}/ \
    && unzip -o ${ROOT}/${OLFS_DISTRO}/opendap.war -d ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/ \
    && echo "Cleaning up OLFS distribution files."  >&2 \
    && rm -rvf ${ROOT}/${OLFS_DISTRO} ./${OLFS_DISTRO}.tgz

RUN set -e \
    && echo "Installing the latest dynamic robots.txt distribution (${OLFS_VERSION})."  >&2 \
    && ls -l ./robots* \
    && tar -C ${ROOT} -xzf ./${ROBOTS_DISTRO}.tgz \
    && ls -l ${ROOT}/${ROBOTS_DISTRO} \
    && echo "Unpacking dynamic robots.txt warfile..."  >&2 \
    && unzip -o ${ROOT}/${ROBOTS_DISTRO}/ROOT.war -d ${CATALINA_HOME}/webapps/ROOT/ \
    && echo "Cleaning up dynamic robots.txt distribution files..."  >&2 \
    && rm -rvf ${ROOT}/${ROBOTS_DISTRO} ${ROBOTS_DISTRO}.tgz

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs

################################################################
# Clean up the Hyrax distribution binaries.
#
#
################################################################

################################################################
# retrieve and install the ncWMS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ARG NCWMS_VERSION
ENV NCWMS_VERSION=${NCWMS_VERSION:-"2.5.2"}
RUN echo "NCWMS_VERSION: ${NCWMS_VERSION}"
ENV NCWMS_WAR_URL="https://github.com/Reading-eScience-Centre/ncwms/releases/download/ncwms-${NCWMS_VERSION}/ncWMS2.war"
RUN echo "NCWMS_WAR_URL: ${NCWMS_WAR_URL}"

RUN if [ $USE_NCWMS = "true" ]; then \
        echo "Installing ncWMS..."; \
        curl -sfSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war; \
        unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS2/; \
        rm -rf /dev/shm/*; \
    else \
        echo "ncWMS will NOT be installed."; \
    fi

# set a default ncWMS admin if DEVELOPER_MODE is enabled.
RUN if [ ${DEVELOPER_MODE} = "true" ] && [ $USE_NCWMS = "true" ]; then \
        echo "DEVELOPER MODE: Adding ncWMS admin credentials"; \
        sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml; \
    else \
        echo "No ncWMS admin credentials installed."; \
    fi
    
#
# make ncWMS work without further configuration 
# We will need to adjust this target if we
# decide to run as a different (not root) user.
COPY ncWMS_config.xml /root/.ncWMS2/config.xml
RUN  chmod +r /root/.ncWMS2/config.xml

COPY olfs_viewers.xml /tmp/olfs_viewers.xml
RUN if [ $USE_NCWMS = "true" ]; then \
        # If we're installing ncWMS then we copy 
        # to the server a viewers.xml which has
        # been templated so that the ncWMS host can be installed 
        # at startup.
        mv /tmp/olfs_viewers.xml ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/viewers.xml; \
    else \
        echo "Skipping OLFS/ncWMS confguration installation."; \
    fi

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
    && autoreconf -vif \
    && ./configure

# In order to get the executable "testsuite" to build we have to run
# "make check" But that will fail at build time so the "make check" call
# ends up pretty tortured to avoid a build error.
RUN set -e \
    && cd ${TEST_INSTALL_DIR} \
    && make testsuite > mk.log 2>&1 \
    && echo "SUCCESS: hyrax_regression_tests ready!"
################################################################

RUN ls -l /usr/libexec/

################################################################
# TEMPORARY
# Grab the cleanup files script for managing orphaned files
# from fileout_netcdf
COPY cleanup_files.sh /
RUN chmod +x /cleanup_files.sh
# TEMPORARY
################################################################


COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8009
EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN chown -R bes /etc/bes
USER root

CMD ["-"]

