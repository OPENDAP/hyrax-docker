###
# Dockerfile for Hyrax OLFS
###

FROM unidata/tomcat-docker:8

MAINTAINER support@opendap.org

USER root

#
# The --build-arg USE_NCWMS can be set to "true" in order to 
# add the ncWMS application to the build.
ARG USE_NCWMS
ENV USE_NCWMS ${USE_NCWMS:-"false"}
RUN set -e && \
    if [ $USE_NCWMS = "true" ];then echo "NCWMS: ENABLED"; else echo "NCWMS: DISABLED"; fi


###
# Grab and unzip the OLFS
###
# Tomcat environment?
ENV PATH $CATALINA_HOME/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

# Installs the OPeNDAP security public key.
# TODO: We should get this from a well known key-server instead.
RUN echo "Adding OPeNDAP Public Security Key"
ENV OPENDAP_PUBLIC_KEY_FILE="security_at_opendap.org.pub.asc"
ENV OPENDAP_PUBLIC_KEY_URL="https://www.opendap.org/${OPENDAP_PUBLIC_KEY_FILE}"
RUN set -e \
    && curl -s $OPENDAP_PUBLIC_KEY_URL > $OPENDAP_PUBLIC_KEY_FILE \
    && gpg --import $OPENDAP_PUBLIC_KEY_FILE

# HYRAX VERSION INFO
ENV HYRAX_VERSION=1.13.5 
ENV OLFS_VERSION=1.16.4

ENV OLFS_WAR_URL="https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz"

###############################################################
# Retrieve, verify, and install the OLFS web application
RUN set -e \
    && echo "Retrieving And Installing OLFS-${OLFS_VERSION}" \
    && curl -sfSL ${OLFS_WAR_URL} > olfs-${OLFS_VERSION}.tgz \
    && curl -sfSL ${OLFS_WAR_URL}.sig > olfs-${OLFS_VERSION}.tgz.sig \
    && echo "Verifying tarball..." \
    && gpg --verify olfs-${OLFS_VERSION}.tgz.sig olfs-${OLFS_VERSION}.tgz \
    && echo "Unpacking tarball..." \
    && tar -C /dev/shm -xzf olfs-${OLFS_VERSION}.tgz \
    && echo "Unpacking warfile..." \
    && unzip -o /dev/shm/olfs-${OLFS_VERSION}-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ \
    && echo "Cleaning up." \
    && rm -rf /dev/shm/* olfs-${OLFS_VERSION}.tgz*

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs 


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

# Fix ownership and access permissions
RUN mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs && \
    chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs && \
    chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs

##########################################################################################
# The following is an effort to tweak the security policy to allow the JULI code to
# to look at webapps/opendap/WEB-INF/classes/logging.properties Even though this
# file does not exist and the code will move on to other locations the fact that 
# it trys to look at it is enough to alert the security manager.
#
# COPY logging_config.policy /tmp/policy
# RUN set -e \
#    && lines=`cat ${CATALINA_HOME}/conf/catalina.policy | wc -l` \
#    && insert=`grep -n 'grant codeBase \"file:\${catalina.home}/bin/tomcat-juli.jar' ${CATALINA_HOME}/conf/catalina.policy \
#    | awk '{split($0,s,":"); print s[1];}' -` \
#    && muh_tail=`expr $lines - $insert + 1` \
#    && echo "lines: $lines insert: $insert muh_tail: $muh_tail" \
#    && head -$insert ${CATALINA_HOME}/conf/catalina.policy > /tmp/catalina.policy \
#    && cat /tmp/policy >> /tmp/catalina.policy \
#    && tail -n $muh_tail ${CATALINA_HOME}/conf/catalina.policy >> /tmp/catalina.policy \
#    && cp /tmp/catalina.policy ${CATALINA_HOME}/conf/catalina.policy \
#    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/catalina.policy \
#    && echo "" \
#    && echo "Updated catalina.policy: " \
#    && cat ${CATALINA_HOME}/conf/catalina.policy
##########################################################################################
 

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh && cat /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["-"]
