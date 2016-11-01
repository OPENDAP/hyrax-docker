###
# Dockerfile for Hyrax OLFS
###

FROM unidata/tomcat-docker:8

MAINTAINER Gareth.Williams@csiro.au

USER root

# underlying debian container instructions recommend not updating
#RUN \
#    apt-get install -y unzip && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Grab and unzip the OLFS
###

ENV HYRAX_VERSION=1.13.1 OLFS_VERSION=1.16.0
ENV OLFS_WAR_URL=https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz
ENV NCWMS_WAR_URL=http://search.maven.org/remotecontent?filepath=uk/ac/rdg/resc/ncWMS/2.2.2/ncWMS-2.2.2.war
# or get from https://github.com/Reading-eScience-Centre/edal-java/releases

RUN curl -fSL ${OLFS_WAR_URL} | tar -C /dev/shm -xzf -  && \
    unzip -o /dev/shm/olfs-${OLFS_VERSION}-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ && \
    rm -rf /dev/shm/*
# set host for bes that olfs will contact - this is expected to be over docker's internal network
RUN sed -i 's/localhost/besd/' ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/olfs.xml

RUN curl -fSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war && \
    unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS/ && \
    rm -rf /dev/shm/*
# set an ncWMS admin even though it is not needed given a custom config.xml will be used
RUN sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml 
# make ncWMS work without further configuration
COPY config.xml ${CATALINA_HOME}/.ncWMS2/config.xml

# first step to enable ncWMS and godiva
# entrypoint will take second step to set the client visible host:port
COPY fix_viewers.xml.pl /tmp/fix_viewers.xml.pl
RUN perl -pi /tmp/fix_viewers.xml.pl ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml
ENV OLFS_WMS_VIEWERS_HOSTPORT=localhost:8080

RUN mkdir -p /etc/olfs

###
# Expose ports
###

EXPOSE 8080 8443

RUN chown -R tomcat:tomcat /etc/olfs && \
    chmod 700 /etc/olfs


COPY entrypoint.sh /
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

USER tomcat

CMD ["catalina.sh", "run"]
