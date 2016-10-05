###
# Dockerfile for Hyrax OLFS
###

FROM unidata/tomcat-docker:8

MAINTAINER Gareth.Williams@csiro.au

###
# Usual maintenance
###

USER root

RUN \
    apt-get install -y unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Grab and unzip the OLFS
###

ENV HYRAX_VERSION=1.13.1 OLFS_VERSION=1.16.0
ENV OLFS_WAR_URL=https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz

RUN curl -fSL ${OLFS_WAR_URL} | tar -C /dev/shm -xzf -  && \
    unzip -o /dev/shm/olfs-${OLFS_VERSION}-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ && \
    rm -rf /dev/shm/*

###
# Default olfs config
###

RUN mkdir -p ${CATALINA_HOME}/content/opendap

#COPY files/threddsConfig.xml ${CATALINA_HOME}/content/thredds/threddsConfig.xml

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

USER tomcat

###
# Start container
###

CMD ["catalina.sh", "run"]
