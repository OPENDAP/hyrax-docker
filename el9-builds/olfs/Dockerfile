###
# Dockerfile for Hyrax OLFS
###

#
FROM rockylinux:8
LABEL org.opencontainers.image.authors="support@opendap.org"
USER root
ENV HR="######################################################"
ENV TARGET_OS="el9"
ENV ARCH="x86_64"
ENV java_version="java-21-openjdk"
# rocky9 comes with python 3.9 by default.
ENV python_version="3.9"
RUN echo "Python Version: $(python3 --version) (config says we want: $python_version)"
ENV core_dnf_packages="procp unzip"
# Stuff we need for hyrax_regression_tests
# ENV regression_test_dnf_packages="git make autoconf automake diffutils"

ENV developer_dnf_packages="curl unzip which emacs vim bc awscli"
#ENV developer_dnf_packages="which diffutils emacs vim jq  procps git bc valgrind gdb awscli"



RUN export NOW="$(date +%s)"
ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"${NOW}"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG TOMCAT_VERSION
ENV TOMCAT_VERSION ${TOMCAT_VERSION:-"11.0.7"}
RUN echo "TOMCAT_VERSION: ${TOMCAT_VERSION}"
ENV TOMCAT_DISTRO="apache-tomcat-${TOMCAT_VERSION}"
COPY "${TOMCAT_DISTRO}.tar.gz" /
RUN ls -l /apache-tomcat-*  >&2

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

ARG OLFS_VERSION
ENV OLFS_VERSION=${OLFS_VERSION:-"unknown"}
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

ARG OLFS_DISTRO
ENV OLFS_DISTRO=${OLFS_DISTRO:-"olfs-${OLFS_VERSION}-webapp"}
RUN echo "OLFS_DISTRO: ${OLFS_DISTRO}"
COPY ${OLFS_DISTRO}.tgz /${OLFS_DISTRO}.tgz

ARG ROBOTS_DISTRO
ENV ROBOTS_DISTRO=${ROBOTS_DISTRO:-"robots-olfs-${OLFS_VERSION}-webapp"}
RUN echo "ROBOTS_DISTRO: ${ROBOTS_DISTRO}"
COPY ${ROBOTS_DISTRO}.tgz /${ROBOTS_DISTRO}.tgz

LABEL vendor="OPeNDAP"
LABEL org.opendap.olfs.version=${OLFS_VERSION}
LABEL org.opendap.olfs.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"


# The --build-arg USE_NCWMS can be set to "true" in order to 
# add the ncWMS application to the build.
ARG USE_NCWMS
ENV USE_NCWMS ${USE_NCWMS:-"false"}
RUN set -e && \
    if [ $USE_NCWMS = "true" ];then echo "NCWMS: ENABLED"; else echo "NCWMS: DISABLED"; fi

#
# The --build-arg NCWMS_BASE can be set to the base URL for ncWMS.
# The entrypoint.sh code defaults it to
# the URL: https://localhost:8080 if the environment variable NCWMS_BASE
# is not in the shell from which the entrypoint.sh script is called.
ARG NCWMS_BASE
ENV NCWMS_BASE ${NCWMS_BASE:-"https://localhost:8080"}
RUN set -e && \
    if [ $USE_NCWMS = "true" ];then echo "NCWMS_BASE: {$NCWMS_BASE}"; fi


################################################################
# Update and install the needful.
#
# Installing utils for debugging convenience.
#
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
    && dnf install -y $core_dnf_packages $regression_test_dnf_packages $developer_dnf_packages \
    && dnf clean all




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
    && rm -rvf /usr/share/tomcat/webapps/* >&2 \
    && mkdir -p /var/log/tomcat \
    && chown -R tomcat:tomcat /var/log/tomcat /home/tomcat
COPY tomcat.service /etc/systemd/system/tomcat.service
RUN set -e && systemctl enable tomcat
#RUN firewall-cmd --add-port 8080/tcp --permanent
#RUN firewall-cmd --reload

ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN set -e && echo "CATALINA_HOME: ${CATALINA_HOME}" >&2

# Install our modified server.xml so that the server compresses responses.
COPY tomcat11-server.xml /
RUN set -e \
    && mv /tomcat11-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml

RUN set -e \
    && echo "Cleaning up Tomcat distribution files..." >&2 \
    && rm -fv "/${TOMCAT_DISTRO}.tar.gz"


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
    && mkdir -p $(readlink -f ${CATALINA_HOME})/webapps/opendap/ \
    && unzip -o ${ROOT}/${OLFS_DISTRO}/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ \
    && echo "Cleaning up."  >&2 \
    && rm -rf ${ROOT}/${OLFS_DISTRO} ./${OLFS_DISTRO}.tgz

RUN set -e \
    && echo "Installing the latest dynamic robots.txt distribution (${OLFS_VERSION})."  >&2 \
    && ls -l ./robots* \
    && tar -C ${ROOT} -xzf ./${ROBOTS_DISTRO}.tgz \
    && ls -l ${ROOT}/${ROBOTS_DISTRO} \
    && echo "Unpacking dynamic robots.txt warfile..."  >&2 \
    && unzip -o ${ROOT}/${ROBOTS_DISTRO}/ROOT.war -d ${CATALINA_HOME}/webapps/ROOT/ \
    && echo "Cleaning up dynamic robots.txt snapshot..."  >&2 \
    && rm -rf ${ROOT}/${ROBOTS_DISTRO} ${ROBOTS_DISTRO}.tgz

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs

################################################################
# Clean up the distribution binaries.
#
RUN rm -vf  /olfs*.tgz /robots*.tgz /apache*
#
################################################################



# set host for bes that olfs will contact - this is expected to be over docker's internal network
ARG BES_HOST
ENV BES_HOST ${BES_HOST:-besd}
RUN sed -i "s/localhost/${BES_HOST}/" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/olfs.xml

#
# Setting NCWMS_HOST to the protocol, host, and port 
# section of the publicly acessible URL of the 
# ncWMS service. Using localhost is all well and good
# for testing but this needs to be settable at 
# build time for sure and maybe even docker runtime? 
#
COPY olfs_viewers.xml /tmp/olfs_viewers.xml
RUN set -e \
    && if [ $USE_NCWMS = "true" ]; then \
        mv /tmp/olfs_viewers.xml ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml; \
    else \
        echo "Skipping OLFS/ncWMS confguration installation."; \
    fi
    
###
# Expose ports
###

EXPOSE 8080 8443

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh && cat /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["-"]
