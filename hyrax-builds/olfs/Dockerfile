###
# Dockerfile for Hyrax OLFS
###

# FROM unidata/tomcat-docker:8
FROM tomcat:8
MAINTAINER support@opendap.org

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG AWS_ACCESS_KEY_ID
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-"unknown"}
RUN echo "AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}"

ARG AWS_SECRET_ACCESS_KEY
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-"unknown"}
RUN echo "AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}"

ARG OLFS_VERSION
ENV OLFS_VERSION=${OLFS_VERSION:-"unknown"}
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

LABEL vendor="OPeNDAP"
LABEL org.opendap.olfs.version=${OLFS_VERSION}
LABEL org.opendap.olfs.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

USER root

# Update OS and install ps (and other filesystem utils)
RUN set -e \
    && apt-get update \
    && apt-get install -y procps awscli

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
ENV OLFS_PACKAGE="s3://opendap.travis.build/olfs-${OLFS_VERSION}-webapp.tgz"
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

###############################################################
# Retrieve, verify, and install the OLFS web application
# In the following, replaced unzip with jar because unzip was failing with a message
# about the archive containing a 'loop' of some sort. The original line was:
#     unzip -o /dev/shm/olfs-snapshot-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/
# and the new line is:
#     (cd ${CATALINA_HOME}/webapps/opendap/ && jar -xf /dev/shm/olfs-snapshot-webapp/opendap.war)
# 
RUN set -e \
    && echo "Retrieving and installing the latest olfs snapshot (${OLFS_VERSION})." \
    && aws --region=us-east-1 s3 cp ${OLFS_PACKAGE} olfs-webapp.tgz \
    && tar -C /dev/shm -xzf olfs-webapp.tgz \
    && ls -l /dev/shm/olfs-webapp \
    && echo "Unpacking warfile..." \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/ \
    && (cd ${CATALINA_HOME}/webapps/opendap/ && jar -xf /dev/shm/olfs-webapp/opendap.war) \
    && echo "Cleaning up." \
    && rm -rf /dev/shm/* olfs-webapp.tgz

# Clear these values so they do not persist in the container!
ENV AWS_ACCESS_KEY_ID=
ENV AWS_SECRET_ACCESS_KEY=
RUN echo "unset AWS_ACCESS_KEY_ID"     >> ~/.bash_profile
RUN echo "unset AWS_SECRET_ACCESS_KEY" >> ~/.bash_profile
RUN echo "unset AWS_ACCESS_KEY_ID"     >> ~/.bashrc
RUN echo "unset AWS_SECRET_ACCESS_KEY" >> ~/.bashrc


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