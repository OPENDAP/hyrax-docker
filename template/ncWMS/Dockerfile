###
# Dockerfile for ncWMS-2.2.2
###


#FROM unidata/tomcat-docker:8
FROM tomcat:8-jre8
MAINTAINER support@opendap.org

USER root

# Update OS and install ps (and other filesystem utils)
RUN set -e \
    && apt-get update \
    && apt-get install -y procps


ARG DEVELOPER_MODE
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"false"}
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi


RUN echo "CATALINA_HOME: ${CATALINA_HOME}"


# underlying debian container instructions recommend not updating
#RUN \
#    apt-get install -y unzip && \
#    apt-get clean && \
#    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

###
# Grab and unzip ncWMS
###
ENV NCWMS_WAR_URL=https://github.com/Reading-eScience-Centre/ncwms/releases/download/ncwms-2.4.2/ncWMS2.war
# or get from https://github.com/Reading-eScience-Centre/edal-java/releases

###############################################################
# retrieve and install the ncWMS web application
#
RUN curl -sfSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war && \
    unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS2/ && \
    rm -rf /dev/shm/*
#
# set an ncWMS admin even though it is not needed given a custom config.xml will be used
RUN if [ ${DEVELOPER_MODE} = "true" ]; then \
        echo "DEVELOPER MODE: Adding ncWMS admin credentials"; \
        sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml; \
    else \
        echo "No ncWMS admin credentials installed."; \
    fi


#
# make ncWMS work without further configuration
# @TODO We will need to adjust this target if we
# decide to run as a different (not root) user.
COPY ncWMS_config.xml /root/.ncWMS2/config.xml
RUN  chmod +r /root/.ncWMS2/config.xml
#
#
# Fix java security policy to allow ncWMS and CORS to do the things.
#
COPY ncwms.policy /
RUN set -e \
    &&  cat /ncwms.policy >> ${CATALINA_HOME}/conf/catalina.policy \
    &&  rm /ncwms.policy


###
# Expose ports
###

EXPOSE 8080 
EXPOSE 8443

# Fix ownership and access permissions
# RUN chown -R tomcat:tomcat ${CATALINA_HOME}/.ncWMS2 /etc/.java && \
#    chmod 700 ${CATALINA_HOME}/.ncWMS2 /etc/.java


COPY entrypoint.sh /
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# leave setting user to gosu
#USER tomcat

CMD ["-"]
