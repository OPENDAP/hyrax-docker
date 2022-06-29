###
# Dockerfile for Hyrax OLFS
###

#
FROM tomcat:9
MAINTAINER support@opendap.org

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG OLFS_VERSION
ENV OLFS_VERSION=${OLFS_VERSION:-"unknown"}
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

ARG OLFS_DISTRO
ENV OLFS_DISTRO=${OLFS_DISTRO:-"olfs-${OLFS_VERSION}-webapp"}
RUN echo "OLFS_DISTRO: ${OLFS_DISTRO}"
COPY ${OLFS_DISTRO}.tgz /${OLFS_DISTRO}.tgz

LABEL vendor="OPeNDAP"
LABEL org.opendap.olfs.version=${OLFS_VERSION}
LABEL org.opendap.olfs.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

USER root

# Update OS and install ps (and other filesystem utils)
#RUN set -e && apt-get -y update

RUN set -e && sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list
RUN set -e && apt-get -oDebug::pkgAcquire::Worker=1 update
RUN set -e && apt-get -y -oDebug::pkgAcquire::Worker=1 upgrade
RUN set -e && apt-get -y install unzip

#
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

###
# Grab and unzip the OLFS
###
# Tomcat environment?
ENV PATH $CATALINA_HOME/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

# SNAPSHOT URLs
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

###############################################################
# Retrieve, verify, and install the OLFS web application
# In the following, replaced unzip with jar because unzip was failing with a message
# about the archive containing a 'loop' of some sort. The original line was:
#     unzip -o /dev/shm/olfs-snapshot-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/
# and the new line is:
#     (cd ${CATALINA_HOME}/webapps/opendap/ && jar -xf /dev/shm/olfs-snapshot-webapp/opendap.war)
#
ENV ROOT=/dev/shm
RUN echo "Installing the latest olfs snapshot (${OLFS_VERSION}.tgz)."
RUN set -e \
    && tar -C ${ROOT} -xzvf /${OLFS_DISTRO}.tgz \
    && ls -l ${ROOT} \
    && echo "Unpacking warfile..."  >&2 \
    && mkdir -p $(readlink -f ${CATALINA_HOME})/webapps/opendap/ \
    && unzip -o ${ROOT}/${OLFS_DISTRO}/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ \
    && echo "Cleaning up."  >&2 \
    && rm -rf ${ROOT}/${OLFS_DISTRO} /${OLFS_DISTRO}.tgz

#    && echo "Unpacking warfile ${ROOT}/${OLFS_DISTRO}/opendap.war" \
#    && mkdir -p ${CATALINA_HOME}/webapps/opendap/ \
#    && (cd ${CATALINA_HOME}/webapps/opendap/ && jar -xf ${ROOT}/${OLFS_DISTRO}/opendap.war) \
#    && echo "Cleaning up." \
#    && rm -rf ${ROOT}/${OLFS_DISTRO} /${OLFS_DISTRO}.tgz


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
