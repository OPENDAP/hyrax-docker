###
# Dockerfile for Hyrax BES
###

FROM centos:7
#FROM unidata/tomcat-docker:8

MAINTAINER support@opendap.org

USER root

# Recommended maintenance
RUN \
    yum -y install which unzip tomcat && \
    yum -y update && \
    yum clean all 


ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

# Install the BES from RPM
ENV HYRAX_VERSION=1.13.4 
ENV OLFS_VERSION=1.16.3

ENV LIBDAP_RPM="https://www.opendap.org/pub/binary/hyrax-1.13.4/centos-7.x/libdap-3.19.0-1.el7.centos.x86_64.rpm"
ENV BES_RPM="https://www.opendap.org/pub/binary/hyrax-1.13.4/centos-7.x/bes-3.18.0-1.static.el7.centos.x86_64.rpm"
ENV OLFS_WAR_URL="https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz"

RUN yum -y install $LIBDAP_RPM $BES_RPM
RUN echo "besdaemon is here: "`which besdaemon`


# Retrieve and install the OLFS web application
RUN curl -fSL ${OLFS_WAR_URL} | tar -C /dev/shm -xzf -  && \
    unzip -o /dev/shm/olfs-${OLFS_VERSION}-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ && \
    rm -rf /dev/shm/*

# set host for bes that olfs will contact - this is expected to be over docker's internal network
# RUN sed -i 's/localhost/besd/' ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/olfs.xml

# Fix ownership and access permissions
RUN mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs && \
    chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs && \
    chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs 


COPY entrypoint.sh /
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN  chown -R bes /etc/bes
USER root

# tunables - to be overridden on command line or in docker-compose or ansible
ENV BES_HELP_EMAIL=help@replaceme
ENV BES_SYMLINKS=Yes
# Yes (hyrax docker default overrides rpm default) or No, for symlinks in /usr/share/hyrax


RUN echo "############################" && \
    ls -l /usr/bin/besdaemon /usr/share/tomcat /usr/share/tomcat/webapps && \
    echo "############################" 

CMD ["-"]

