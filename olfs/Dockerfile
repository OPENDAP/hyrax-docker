###
# Dockerfile for Hyrax OLFS
###

FROM unidata/tomcat-docker:8

MAINTAINER support@opendap.org

USER root

# underlying debian container instructions recommend not updating
#RUN \
#    apt-get install -y unzip && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Grab and unzip the OLFS
###

RUN echo "CATALINA_HOME: ${CATALINA_HOME}"

ENV HYRAX_VERSION=1.13.4 OLFS_VERSION=1.16.3
ENV OLFS_WAR_URL=https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz

# Retrieve and intsall the OLFS web application
RUN curl -sfSL ${OLFS_WAR_URL} | tar -C /dev/shm -xzf -  && \
    unzip -o /dev/shm/olfs-${OLFS_VERSION}-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ && \
    rm -rf /dev/shm/*
# set host for bes that olfs will contact - this is expected to be over docker's internal network
RUN sed -i 's/localhost/besd/' ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/olfs.xml


#
# Setting NCWMS_HOST to the protocol, host, and port 
# section of the publicly acessible URL of the 
# ncWMS service. Using localhost is all well and good
# for testing but this needs to be settable at 
# build time for sure and maybe even docker runtime? 
#
ENV NCWMS_HOST=http://localhost:8080
COPY olfs_viewers.xml /tmp/olfs_viewers.xml
RUN set -e \
    && echo "---------------------------------------------------------------------------"\
    && ls -la /tmp/olfs_viewers.xml \
    && sed "s+@NCWMS_PUBLIC_HOST_AND_PORT@+${NCWMS_HOST}+g" /tmp/olfs_viewers.xml \
    |  tee ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml \
    && echo "---------------------------------------------------------------------------"\
    && echo "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml "\
    && cat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml \
    && echo "---------------------------------------------------------------------------"

###
# Expose ports
###

EXPOSE 8080 8443

# Fix ownership and access permissions
RUN mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs && \
    chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs && \
    chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs # && \
#    chown -R tomcat:tomcat ${CATALINA_HOME}/.ncWMS2 /etc/.java && \
#    chmod 700 ${CATALINA_HOME}/.ncWMS2 /etc/.java


COPY entrypoint.sh /
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# leave setting ser to gosu
#USER tomcat

CMD ["catalina.sh", "run"]
