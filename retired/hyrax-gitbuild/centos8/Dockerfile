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
FROM centos:8

ENV MAKE "make"

# HYRAX VERSION INFO
ENV HYRAX_VERSION=snapshot
ENV HYRAX_VERSION_LABEL=snapshot

ENV GIT_SERVICE=https://github.com

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"


LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.hyrax.version=snapshot
LABEL org.opendap.hyrax.release-date=${RELEASE_DATE}
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

ARG HYRAX_DEPENDENCIES_BRANCH
ENV HYRAX_DEPENDENCIES_BRANCH ${HYRAX_DEPENDENCIES_BRANCH:-"master"}
RUN set -e && \
    echo "HYRAX_DEPENDENCIES_BRANCH: ${HYRAX_DEPENDENCIES_BRANCH}";

ARG LIBDAP_BRANCH
ENV LIBDAP_BRANCH ${LIBDAP_BRANCH:-"master"}
RUN set -e && \
    echo "LIBDAP_BRANCH: ${LIBDAP_BRANCH}";

ARG BES_BRANCH
ENV BES_BRANCH ${BES_BRANCH:-"master"}
RUN set -e && \
    echo "BES_BRANCH: ${BES_BRANCH}";

ARG H4_BRANCH
ENV H4_BRANCH ${H4_BRANCH:-"master"}
RUN set -e && \
    echo "H4_BRANCH: ${H4_BRANCH}";

ARG H5_BRANCH
ENV H5_BRANCH ${H5_BRANCH:-"master"}
RUN set -e && \
    echo "H5_BRANCH: ${H5_BRANCH}";

ARG OLFS_BRANCH
ENV OLFS_BRANCH ${OLFS_BRANCH:-"master"}
RUN set -e && \
    echo "OLFS_BRANCH: ${OLFS_BRANCH}";


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
ENV DEVELOPER_MODE ${DEVELOPER_MODE:-"true"}
RUN set -e && \
    if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi


# Update and install the needful.
RUN set -e \
    && yum -y install \
        java-1.8.0-openjdk \
        java-1.8.0-openjdk-devel \
        ant \
        ant-junit \
        file \
        junit \
        git \
        gcc-c++ \
        flex \
        bison \
        make \
        cmake \
        autoconf \
        automake \
        libtool \
        emacs \
        openssl-devel \
        libuuid-devel \
        readline-devel \
        zlib-devel \
        bzip2 \
        bzip2-devel \
        libjpeg-devel \
        libxml2-devel \
        curl-devel \
        cppunit \
        cppunit-devel \
        unzip \
        vim \
        bc  \
        tomcat \
    && yum -y update \
    && yum clean all 

RUN set -e \
    && yum -y install \
        libicu-devel \
        libicu \
    && yum -y update \
    && yum clean all


# Tomcat environment (Tomcat installed above by via yum)
ENV CATALINA_HOME /usr/share/tomcat
ENV PATH ${CATALINA_HOME}/bin:$PATH
RUN echo "CATALINA_HOME: $CATALINA_HOME"

RUN mkdir hyrax \
    && mkdir hyrax/build

ENV prefix /hyrax/build
RUN echo "prefix: ${prefix}"

ENV PATH $prefix/bin:$prefix/deps/bin:$PATH
RUN echo "PATH: ${PATH}"

ENV BES_SITE_CONF "${prefix}/etc/bes/site.conf"
RUN echo "BES_SITE_CONF: ${BES_SITE_CONF}"

###############################################################
# Retrieve, build, and install hyrax-dependencies
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "HYRAX-DEPS: Cloning hyrax-dependencies" \
    && cd /hyrax \
    && git clone --depth 1 ${GIT_SERVICE}/OPENDAP/hyrax-dependencies hyrax-dependencies \
    && cd hyrax-dependencies \
    && echo "HYRAX-DEPS: Checking out branch: ${HYRAX_DEPENDENCIES_BRANCH}" \
    && git checkout ${HYRAX_DEPENDENCIES_BRANCH} \
    && echo "hyrax-dependencies" \
    && ls -l

RUN set -e \
    && cd /hyrax/hyrax-dependencies \
    && echo "HYRAX-DEPS: make (prefix=${prefix})" \
    && $MAKE for-static-rpm

#RUN set -e \
#    && cd /hyrax/hyrax-dependencies \
#    && echo "HYRAX-DEPS: make (prefix=${prefix})" \
#    && make proj

#RUN set -e \
#    && cd /hyrax/hyrax-dependencies \
#    && echo "HYRAX-DEPS: make (prefix=${prefix})" \
#    && make gdal4

RUN set -e \
    && cd /hyrax/hyrax-dependencies \
    && echo "Hyrax Dependencies Items" \
    && ls -l *stamp \
    && ls -l ${prefix}/deps/lib

###############################################################

###############################################################
# Retrieve, build, and install libdap
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "LIBDAP4: Cloning." \
    && cd /hyrax \
    && git clone --depth 1 ${GIT_SERVICE}/OPENDAP/libdap4  libdap4 \
    && cd libdap4 \
    && echo "LIBDAP4: Checking out branch: ${LIBDAP_BRANCH}" \
    && git checkout ${LIBDAP_BRANCH}

RUN set -e \
    && pwd \
    && cd /hyrax/libdap4 \
    && echo "LIBDAP4: autoreconf" \
    && autoreconf -vif \
    && echo "LIBDAP4: ./configure (prefix=${prefix})" \
    && ./configure --prefix=${prefix} --enable-developer \
    && echo "LIBDAP4: make" \
    && $MAKE

RUN set -e \
    && cd /hyrax/libdap4 \
    && echo "LIBDAP4: make check" \
    && make -j20 check \
    && echo "LIBDAP4: make install" \
    && make install

###############################################################

###############################################################
# Retrieve, build, and install BES
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "BES: Cloning." \
    && cd /hyrax \
    && git clone --depth 1 ${GIT_SERVICE}/OPENDAP/bes  bes \
    && cd bes \
    && echo "BES: Updating submodules" \
    && git submodule update --init \
    && echo "BES: Checking out branch: ${BES_BRANCH}" \
    && git checkout ${BES_BRANCH} \
    && echo "BES: Checking out hdf4_handler branch: ${H4_BRANCH}" \
    && cd modules/hdf4_handler \
    && git checkout ${H4_BRANCH} \
    && echo "BES: Checking out hdf5_handler branch: ${H5_BRANCH}" \
    && cd ../hdf5_handler \
    && git checkout ${H5_BRANCH}

RUN set -e \
    && cd /hyrax/bes \
    && echo "BES: autoreconf" \
    && autoreconf -vif \
    && echo "BES: ./configure (prefix=${prefix})" \
    && ./configure --prefix=${prefix} --with-dependencies=${prefix}/deps --enable-developer \
    && echo "BES: make" \
    && $MAKE

RUN set -e \
    && cd /hyrax/bes \
    && echo "BES: make check" \
    && make -j20 check \
    && echo "BES: make install" \
    && make install

RUN set -e \
    && echo "Creating user 'bes'" \
    &&  useradd -U -m bes

RUN set -e \
    && cd /hyrax/bes \
    && echo "Setting BES User and Group to the 'bes' user in ${BES_SITE_CONF}" >&2 \
    && echo "BES.User=bes" >> "${BES_SITE_CONF}" \
    && echo "BES.Group=bes" >> "${BES_SITE_CONF}"

RUN set -e \
    && echo "Assigning ownership of the BES deployment to the 'bes' user." >&2 \
    && chown -v -R bes:bes ${prefix}

###############################################################


###############################################################
# Retrieve, build, and install OLFS
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV OLFS_TARGET="server"
ENV HYRAX_DEPLOYMENT_CONTEXT="opendap"
ENV NGAP_DEPLOYMENT_CONTEXT="ROOT"
RUN set -e \
    && echo "OLFS: Cloning" \
    && cd /hyrax \
    && git clone --depth 1 ${GIT_SERVICE}/OPENDAP/olfs olfs \
    && cd olfs \
    && echo "OLFS: Checking out branch: ${OLFS_BRANCH}" \
    && git checkout ${OLFS_BRANCH} \
    && echo "OLFS: Building target: ${OLFS_TARGET}" \
    && ant ${OLFS_TARGET} \
    && echo "OLFS: Unpacking opendap.war file..." \
    && unzip -o build/dist/opendap.war -d ${CATALINA_HOME}/webapps/${HYRAX_DEPLOYMENT_CONTEXT}/ \
    && echo "OLFS: Cleaning up." \
    && ant clean

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
    && git checkout master \
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


COPY entrypoint.sh /
RUN  set -e && chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
#RUN  set -e && chown -R bes /etc/bes
USER root

CMD ["-"]

