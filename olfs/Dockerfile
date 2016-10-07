###
# Dockerfile for Hyrax OLFS
###

FROM unidata/tomcat-docker:8

MAINTAINER Gareth.Williams@csiro.au

###
# Usual maintenance
###

USER root

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
RUN sed -i 's/localhost/besd/' ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/olfs.xml

RUN curl -fSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war && \
    unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS/ && \
    rm -rf /dev/shm/*
RUN sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml 
COPY config.xml ${CATALINA_HOME}/.ncWMS2/config.xml
COPY viewers.xml ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml

###
# Default olfs config
###

RUN mkdir -p /etc/olfs

###
# Tomcat users
###

#COPY files/tomcat-users.xml ${CATALINA_HOME}/conf/tomcat-users.xml

###
# Tomcat Java Options
###

#COPY files/setenv.sh $CATALINA_HOME/bin/setenv.sh

#COPY files/javaopts.sh $CATALINA_HOME/bin/javaopts.sh

#RUN chmod 755 $CATALINA_HOME/bin/*.sh

###
# Expose ports
###

EXPOSE 8080 8443

###
# Reasserting ownership and permissions from parent container
# https://github.com/docker/docker/issues/6119
# https://github.com/docker/docker/issues/7390
###

RUN chown -R tomcat:tomcat ${CATALINA_HOME} && \
    chmod 400 ${CATALINA_HOME}/conf/* && \
    chmod 300 ${CATALINA_HOME}/logs/.

RUN chown -R tomcat:tomcat /etc/olfs && \
    chmod 700 /etc/olfs

USER tomcat

###
# Start container
###

CMD ["catalina.sh", "run"]
