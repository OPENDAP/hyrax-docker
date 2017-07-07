###
# Dockerfile for ncWMS-2.2.2
###


#FROM unidata/tomcat-docker:8
FROM tomcat:8-jre8
MAINTAINER support@opendap.org

USER root

# underlying debian container instructions recommend not updating
#RUN \
#    apt-get install -y unzip && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Grab and unzip ncWMS
###
ENV NCWMS_WAR_URL=http://search.maven.org/remotecontent?filepath=uk/ac/rdg/resc/ncWMS/2.2.2/ncWMS-2.2.2.war
# or get from https://github.com/Reading-eScience-Centre/edal-java/releases

###############################################################
# retrieve and install the ncWMS web application
#
RUN curl -sfSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war && \
    unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS/ && \
    rm -rf /dev/shm/*
#
# set an ncWMS admin even though it is not needed given a custom config.xml will be used
RUN sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml 
#
# make ncWMS work without further configuration
COPY config.xml ${CATALINA_HOME}/.ncWMS2/config.xml
RUN  chmod +r ${CATALINA_HOME}/.ncWMS2/config.xml
#COPY cors.properties ${CATALINA_HOME}/webapps/ncWMS/WEB-INF/classes
#RUN  chmod +r ${CATALINA_HOME}/webapps/ncWMS/WEB-INF/classes

#
# first step to enable ncWMS and godiva
# entrypoint will take second step to set the client visible host:port
#COPY fix_viewers.xml.pl /tmp/fix_viewers.xml.pl
#RUN set -e && perl -pi /tmp/fix_viewers.xml.pl ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml
#ENV OLFS_WMS_VIEWERS_HOSTPORT=localhost:8080
###############################################################

###
# Expose ports
###

EXPOSE 8080 8443

# Fix ownership and access permissions
# RUN chown -R tomcat:tomcat ${CATALINA_HOME}/.ncWMS2 /etc/.java && \
#    chmod 700 ${CATALINA_HOME}/.ncWMS2 /etc/.java


COPY entrypoint.sh /
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# leave setting ser to gosu
#USER tomcat

CMD ["-"]
