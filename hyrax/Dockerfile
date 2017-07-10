###############################################################################################
# 
# Dockerfile for single container Hyrax
#
#
# Some shell state reference:
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
#
# In general use "set -e" when running commands that matter and don't use
# it for debugging stuff.

FROM centos:7

MAINTAINER support@opendap.org

USER root

# Update and install the needful.
RUN \
    yum -y install which unzip tomcat && \
    yum -y update && \
    yum clean all 

# Tomcat environment (Tomcat installed above by via yum)
ENV CATALINA_HOME /usr/share/tomcat
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
ENV HYRAX_VERSION=1.13.4 
ENV LIBDAP_VERSION=3.19.0-1
ENV BES_VERSION=3.18.0-1
ENV OLFS_VERSION=1.16.3

# RELEASE URLs
ENV LIBDAP_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/centos-7.x/libdap-${LIBDAP_VERSION}.el7.centos.x86_64.rpm"
ENV BES_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/centos-7.x/bes-${BES_VERSION}.static.el7.centos.x86_64.rpm"
ENV OLFS_WAR_URL="https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz"

# Retrieve, verify, and install Libdap
RUN set -e \
    && echo "Retrieving, verifying, and installing libdap. rpm: $LIBDAP_RPM" \
    && curl -s $LIBDAP_RPM > ./libdap.rpm \
    && curl -s $LIBDAP_RPM.sig > ./libdap.rpm.sig \
    && gpg -v --verify ./libdap.rpm.sig ./libdap.rpm \
    && ls -l ./libdap* \
    && yum -y install ./libdap.rpm 
    # rm -f libdap.*

# gpg --keyserver certserver.pgp.com --recv-keys 


# Retrieve, verify, and install the BES
RUN set -e \
    && echo "Retrieving, verifying, and installing besd. rpm: $BES_RPM" \
    && curl -s ${BES_RPM} > ./bes.rpm \
    && curl -s ${BES_RPM}.sig > ./bes.rpm.sig \
    && gpg -v --verify ./bes.rpm.sig ./bes.rpm \
    && ls -l ./bes* \
    && yum -y install ./bes.rpm 
    # rm -f bes.*

RUN echo "besdaemon is here: "`which besdaemon`

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
    && rm -rf /dev/shm/*

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs 




###############################################################
# retrieve and install the ncWMS web application
#
ENV NCWMS_WAR_URL=http://search.maven.org/remotecontent?filepath=uk/ac/rdg/resc/ncWMS/2.2.2/ncWMS-2.2.2.war

RUN curl -sfSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war && \
    unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS2/ && \
    rm -rf /dev/shm/*

#
# set an ncWMS admin even though it is not needed given a custom config.xml will be used
RUN sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml 
#
# make ncWMS work without further configuration
COPY ncWMS_config.xml /root/.ncWMS2/config.xml
RUN  chmod +r /root/.ncWMS2/config.xml

#
# first step to enable ncWMS and godiva
# entrypoint will take second step to set the client visible host:port
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
    
    
###############################################################
















COPY entrypoint.sh /
RUN  set -e && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN  set -e && chown -R bes /etc/bes
USER root

# tunables - to be overridden on command line or in docker-compose or ansible
ENV BES_HELP_EMAIL=help@replace.me
ENV BES_SYMLINKS=Yes
# Yes (hyrax docker default overrides rpm default) or No, for symlinks in /usr/share/hyrax


#RUN echo "############################" && \
#    ls -l /usr/bin/besdaemon /usr/share/tomcat /usr/share/tomcat/webapps && \
#    echo "############################" 

CMD ["-"]

