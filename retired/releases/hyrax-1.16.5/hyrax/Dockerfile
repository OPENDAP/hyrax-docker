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
#
# Set one or more individual labels
FROM centos:7

# HYRAX VERSION INFO
ENV HYRAX_VERSION=1.16
ENV HYRAX_VERSION_LABEL=1.16.5
ENV LIBDAP_VERSION=3.20.9-0
ENV BES_VERSION=3.20.10-0
ENV OLFS_VERSION=1.18.10
ENV RELEASE_DATE=2022-01-04


LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.hyrax.version=1.16.5
LABEL org.opendap.hyrax.release-date=2022-01-04
LABEL org.opendap.hyrax.version.is-production="true"

MAINTAINER support@opendap.org

USER root

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


ARG DEVELOPER_MODE
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"false"}
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi

# Update and install the needful.
RUN set -e \
    && yum -y install tomcat unzip which autoconf automake python3 git bc \
    && yum -y update \
    && yum clean all \
    && python3 -m pip install awscli

# Tomcat environment (Tomcat installed above by via yum)
ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

################################################################
# Install the OPeNDAP security public key.
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
# TODO: We should get this from a well known key-server instead.
RUN echo "Adding OPeNDAP Public Security Key"
ENV OPENDAP_PUBLIC_KEY_FILE="security_at_opendap.org.pub.asc"
ENV OPENDAP_PUBLIC_KEY_URL="https://www.opendap.org/${OPENDAP_PUBLIC_KEY_FILE}"
RUN set -e \
    && curl -s $OPENDAP_PUBLIC_KEY_URL > $OPENDAP_PUBLIC_KEY_FILE \
    && gpg --import $OPENDAP_PUBLIC_KEY_FILE
###############################################################


###############################################################
# RELEASE URLs
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV LIBDAP_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/centos-7.x/libdap-${LIBDAP_VERSION}.el7.x86_64.rpm"
ENV BES_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/centos-7.x/bes-${BES_VERSION}.static.el7.x86_64.rpm"
ENV OLFS_WAR_URL="https://www.opendap.org/pub/olfs/olfs-${OLFS_VERSION}-webapp.tgz"
ENV ROBOTS_WAR_URL="https://www.opendap.org/pub/olfs/robots-olfs-${OLFS_VERSION}-webapp.tgz"
###############################################################


###############################################################
# Retrieve, verify, and install Libdap
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving, verifying, and installing libdap. rpm: $LIBDAP_RPM" \
    && curl -s $LIBDAP_RPM > ./libdap.rpm \
    && curl -s $LIBDAP_RPM.sig > ./libdap.rpm.sig \
    && gpg -v --verify ./libdap.rpm.sig ./libdap.rpm \
    && ls -l ./libdap* \
    && yum -y install ./libdap.rpm \
    && rm -f libdap.*

# gpg --keyserver certserver.pgp.com --recv-keys 
###############################################################


###############################################################
# Retrieve, verify, and install the BES
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving, verifying, and installing besd. rpm: $BES_RPM" \
    && curl -s ${BES_RPM} > ./bes.rpm \
    && curl -s ${BES_RPM}.sig > ./bes.rpm.sig \
    && gpg -v --verify ./bes.rpm.sig ./bes.rpm \
    && ls -l ./bes* \
    && yum -y install ./bes.rpm \
    && rm -f bes.*

RUN echo "besdaemon is here: "`which besdaemon`
###############################################################


################################################################
# Retrieve, verify, and install the OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Retrieving And Installing OLFS-${OLFS_VERSION}" \
    && curl -sfSL ${OLFS_WAR_URL} > olfs-${OLFS_VERSION}.tgz \
    && curl -sfSL ${OLFS_WAR_URL}.sig > olfs-${OLFS_VERSION}.tgz.sig \
    && echo "Verifying OLFS-${OLFS_VERSION} tarball..." \
    && gpg --verify olfs-${OLFS_VERSION}.tgz.sig olfs-${OLFS_VERSION}.tgz \
    && echo "Unpacking OLFS-${OLFS_VERSION} tarball..." \
    && tar -C /dev/shm -xzf olfs-${OLFS_VERSION}.tgz \
    && echo "Unpacking OLFS-${OLFS_VERSION} warfile..." \
    && unzip -o /dev/shm/olfs-${OLFS_VERSION}-webapp/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ \
    && echo "Cleaning up OLFS-${OLFS_VERSION} downloads." \
    && rm -rf /dev/shm/* olfs-${OLFS_VERSION}.tgz*

# Retrieve, verify, and install the dynamic robots.txt ROOT web application
RUN set -e \
    && echo "Retrieving And Installing Dynamic Robots.txt webapp version ${OLFS_VERSION}" \
    && curl -sfSL ${ROBOTS_WAR_URL} > robots-olfs-${OLFS_VERSION}.tgz \
    && curl -sfSL ${ROBOTS_WAR_URL}.sig > robots-olfs-${OLFS_VERSION}.tgz.sig \
    && echo "Verifying Dynamic Robots.txt tarball..." \
    && gpg --verify robots-olfs-${OLFS_VERSION}.tgz.sig robots-olfs-${OLFS_VERSION}.tgz \
    && echo "Unpacking Dynamic Robots.txt tarball..." \
    && tar -C /dev/shm -xzf robots-olfs-${OLFS_VERSION}.tgz \
    && echo "Unpacking Dynamic Robots.txt warfile..." \
    && unzip -o /dev/shm/robots-olfs-${OLFS_VERSION}-webapp/ROOT.war -d ${CATALINA_HOME}/webapps/ROOT/ \
    && echo "Cleaning up Dynamic Robots.txt downloads." \
    && rm -rf /dev/shm/* robots-olfs-${OLFS_VERSION}.tgz*

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs 
###############################################################


###############################################################
# retrieve and install the ncWMS web application
#
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

# This is ncWMS-2.4.2
ENV NCWMS_WAR_URL=https://github.com/Reading-eScience-Centre/ncwms/releases/download/ncwms-2.4.2/ncWMS2.war

RUN set -e \
    && if [ $USE_NCWMS = "true" ]; then \
        echo "Installing ncWMS..."; \
        curl -sfSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war; \
        unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS2/; \
        rm -rf /dev/shm/*; \
    else \
        echo "ncWMS will NOT be installed."; \
    fi

# set a default ncWMS admin if DEVELOPER_MODE is enabled.
RUN set -e \
    && if [ ${DEVELOPER_MODE} = "true" ] && [ $USE_NCWMS = "true" ]; then \
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

COPY olfs_viewers.xml /tmp/olfs_viewers.xml
RUN set -e \
    && if [ $USE_NCWMS = "true" ]; then \
        # If we're installing ncWMS then we copy 
        # to the server a viewers.xml which has
        # been templated so that the ncWMS host can be installed 
        # at startup.        
        mv /tmp/olfs_viewers.xml ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml; \
    else \
        echo "Skipping OLFS/ncWMS confguration installation."; \
    fi
    

# Install our modified server.xml so that the server compresses responses.
COPY tomcat7-server.xml /
RUN set -e \
    && mv /tomcat7-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml

###############################################################


################################################################
#
# Retrieve, verify, and install the hyrax_regression_tests
# project
#
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV TEST_INSTALL_DIR="/hyrax_regression_tests"
RUN set -e \
    && echo "Retrieving, and building hyrax regression tests." \
    && echo "h_r_t will be in: ${TEST_INSTALL_DIR}" \
    && mkdir -p ${TEST_INSTALL_DIR} \
    && git clone -v https://github.com/opendap/hyrax_regression_tests ${TEST_INSTALL_DIR} \
    && cd ${TEST_INSTALL_DIR} \
    && git checkout tags/hyrax-${HYRAX_VERSION_LABEL} \
    && autoreconf -vif \
    && ./configure

# In order to get the executable "testsuite" to build we have to run
# "make check" But that will fail at build time so the "make check" call
# ends up pretty tortured to avoid a build error.
RUN set -e \
    && cd ${TEST_INSTALL_DIR} \
    && make testsuite > mk.log 2>&1 \
    && echo "SUCCESS: hyrax_regression_tests ready!"
################################################################

################################################################
# TEMPORARY
# Grab the cleanup files script for managing orphaned files
# from fileout_netcdf
COPY cleanup_files.sh /
RUN chmod +x /cleanup_files.sh
# TEMPORARY
################################################################


COPY entrypoint.sh /
RUN  set -e && chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN  set -e && chown -R bes /etc/bes
USER root

CMD ["-"]

