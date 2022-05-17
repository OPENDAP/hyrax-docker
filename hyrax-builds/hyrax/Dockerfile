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
FROM rockylinux:8

RUN export NOW=`date +%s`

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"${NOW}"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"libdap-${LIBDAP_VERSION}.el8.x86_64.rpm"}
RUN echo "LIBDAP_RPM: ${LIBDAP_RPM}"
COPY ${LIBDAP_RPM} /${LIBDAP_RPM}

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"bes-${BES_VERSION}.static.el8.x86_64.rpm"}
RUN echo "BES_RPM: ${BES_RPM}"
COPY ${BES_RPM} /${BES_RPM}

ARG OLFS_VERSION
ENV OLFS_VERSION=${OLFS_VERSION:-"snapshot"}
RUN echo "OLFS_VERSION: ${OLFS_VERSION}"

ARG OLFS_DISTRO
ENV OLFS_DISTRO=${OLFS_DISTRO:-"olfs-${OLFS_VERSION}-webapp"}
RUN echo "OLFS_DISTRO: ${OLFS_DISTRO}"
COPY ${OLFS_DISTRO}.tgz /${OLFS_DISTRO}.tgz

ARG ROBOTS_DISTRO
ENV ROBOTS_DISTRO=${ROBOTS_DISTRO:-"robots-olfs-${OLFS_VERSION}-webapp"}
RUN echo "ROBOTS_DISTRO: ${ROBOTS_DISTRO}"
COPY ${ROBOTS_DISTRO}.tgz /${ROBOTS_DISTRO}.tgz

LABEL vendor="OPeNDAP"
LABEL org.opendap.hyrax.version=${HYRAX_VERSION}
LABEL org.opendap.hyrax.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

#
# The --build-arg USE_NCWMS can be set to "true" in order to 
# add the ncWMS application to the build.
ARG USE_NCWMS
ENV USE_NCWMS ${USE_NCWMS:-"false"}
RUN if [ $USE_NCWMS = "true" ];then echo "NCWMS: ENABLED"; else echo "NCWMS: DISABLED"; fi

#
# The --build-arg NCWMS_BASE can be set to the base URL for ncWMS.
# The entrypoint.sh code defaults it to
# the URL: https://localhost:8080 if the environment variable NCWMS_BASE
# is not in the shell from which the entrypoint.sh script is called.
ARG NCWMS_BASE
ENV NCWMS_BASE ${NCWMS_BASE:-"https://localhost:8080"}
RUN if [ $USE_NCWMS = "true" ];then echo "NCWMS_BASE: {$NCWMS_BASE}"; fi


ARG DEVELOPER_MODE
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"false"}
RUN if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi

#Get mirrorlist before running yum
#RUN cd /etc/yum.repos.d/
#RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

# Update and install the needful.
RUN dnf -y update
RUN dnf -y install make wget unzip which autoconf automake git bc
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# howerver, to be run, so install them as part of this Dockerfile.
RUN dnf clean all

RUN wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.33/bin/apache-tomcat-9.0.33.tar.gz
RUN tar xvf apache-tomcat-9.0.33.tar.gz -C /usr/share/
RUN ln -s /usr/share/apache-tomcat-9.0.33/ /usr/share/tomcat

# Tomcat environment (Tomcat installed above by via yum)
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
# TODO Is this needed; it's not used in 'olfs' jhrg 4/1/31
ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

RUN useradd -r tomcat


################################################################
# Install the latest libdap snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the libdap rpm: ${LIBDAP_RPM}" \
    && ls -l ./libdap* \
    && dnf -y install ./${LIBDAP_RPM} \
    && rm -f ./${LIBDAP_RPM}

RUN echo "libdap4 is installed."

################################################################
# Install the latest BES snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the latest BES rpm: ${BES_RPM}" \
    && ls -l ./bes* \
    && dnf -y install ./${BES_RPM} \
    && rm -f ./${BES_RPM}

RUN echo "besdaemon is here: "`which besdaemon`

################################################################
# Install the OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

RUN echo "Installing the latest olfs distribution (${OLFS_VERSION})."
RUN set -e \
    && echo "working_dir: "`pwd` \
    && ls -l . \
    && tar -C ${ROOT} -xzvf ./${OLFS_DISTRO}.tgz \
    && ls -l ${ROOT} \
    && echo "Unpacking warfile..." \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/ \
    # && (cd ${CATALINA_HOME}/webapps/opendap/ && jar -xf ${ROOT}/olfs-${OLFS_VERSION}-webapp/opendap.war) \
    && unzip -o ${ROOT}/${OLFS_DISTRO}/opendap.war -d ${CATALINA_HOME}/webapps/opendap/ \
    && echo "Cleaning up." \
    && rm -rf ${ROOT}/${OLFS_DISTRO} ./${OLFS_DISTRO}.tgz

RUN set -e \
    && echo "Installing the latest dynamic robots.txt distribution (${OLFS_VERSION})." \
    && ls -l ./robots* \
    && tar -C ${ROOT} -xzf ./${ROBOTS_DISTRO}.tgz \
    && ls -l ${ROOT}/${ROBOTS_DISTRO} \
    && echo "Unpacking dynamic robots.txt warfile..." \
    && unzip -o ${ROOT}/${ROBOTS_DISTRO}/ROOT.war -d ${CATALINA_HOME}/webapps/ROOT/ \
    && echo "Cleaning up dynamic robots.txt snapshot..." \
    && rm -rf ${ROOT}/${ROBOTS_DISTRO} ${ROBOTS_DISTRO}.tgz

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/logs 


################################################################
# retrieve and install the ncWMS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

# This is ncWMS-2.4.2
ENV NCWMS_WAR_URL=https://github.com/Reading-eScience-Centre/ncwms/releases/download/ncwms-2.4.2/ncWMS2.war

RUN if [ $USE_NCWMS = "true" ]; then \
        echo "Installing ncWMS..."; \
        curl -sfSL ${NCWMS_WAR_URL} -o /dev/shm/ncWMS.war; \
        unzip -o /dev/shm/ncWMS.war -d ${CATALINA_HOME}/webapps/ncWMS2/; \
        rm -rf /dev/shm/*; \
    else \
        echo "ncWMS will NOT be installed."; \
    fi

# set a default ncWMS admin if DEVELOPER_MODE is enabled.
RUN if [ ${DEVELOPER_MODE} = "true" ] && [ $USE_NCWMS = "true" ]; then \
        echo "DEVELOPER MODE: Adding ncWMS admin credentials"; \
        sed -i 'sX</tomcat-users>X<role rolename="ncWMS-admin"/> <user username="admin" password="admin" roles="ncWMS-admin"/> </tomcat-users>X' ${CATALINA_HOME}/conf/tomcat-users.xml; \
    else \
        echo "No ncWMS admin credentials installed."; \
    fi
    
#
# make ncWMS work without further configuration 
# We will need to adjust this target if we
# decide to run as a different (not root) user.
COPY ncWMS_config.xml /root/.ncWMS2/config.xml
RUN  chmod +r /root/.ncWMS2/config.xml

COPY olfs_viewers.xml /tmp/olfs_viewers.xml
RUN if [ $USE_NCWMS = "true" ]; then \
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

RUN ls -l /usr/libexec/

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN chown -R bes /etc/bes
USER root

CMD ["-"]

