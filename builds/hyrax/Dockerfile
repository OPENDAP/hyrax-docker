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

# Add a default base image to keep docker from complaining,
# which is fine because if this ISN'T based on a given image tag,
# everything downstream will fail due to lack of bes, libdap, etc.
ARG BES_IMAGE_TAG
FROM ${BES_IMAGE_TAG:-"rockylinux:8"}

ENV NOW="$(`date +%s`)"
ARG RELEASE_DATE
ENV RELEASE_DATE=${RELEASE_DATE:-"${NOW}"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG TOMCAT_VERSION
ENV TOMCAT_VERSION=${TOMCAT_VERSION:-"9.0.64"}
RUN echo "TOMCAT_VERSION: ${TOMCAT_VERSION}"
ENV TOMCAT_DISTRO="apache-tomcat-${TOMCAT_VERSION}"
COPY "${TOMCAT_DISTRO}.tar.gz" /
RUN ls -l /apache-tomcat-*  >&2

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

# TODO: confirm that LIBDAP_VERSION and BES_VERSION match 
# versions previously installed in base image, fail if not

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

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

ARG DEPLOYMENT_CONTEXT
ENV DEPLOYMENT_CONTEXT=${DEPLOYMENT_CONTEXT:-"opendap"}
RUN echo "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"

LABEL vendor="OPeNDAP"
LABEL org.opendap.hyrax.version=${HYRAX_VERSION}
LABEL org.opendap.hyrax.release-date=${RELEASE_DATE}
LABEL org.opendap.hyrax.version.is-production="false"

LABEL maintainer=support@opendap.org

USER root
WORKDIR /

#
# The --build-arg USE_NCWMS can be set to "true" in order to 
# add the ncWMS application to the build.
ARG USE_NCWMS
ENV USE_NCWMS=${USE_NCWMS:-"false"}
RUN if [ $USE_NCWMS = "true" ];then echo "NCWMS: ENABLED"; else echo "NCWMS: DISABLED"; fi

#
# The --build-arg NCWMS_BASE can be set to the base URL for ncWMS.
# The entrypoint.sh code defaults it to
# the URL: https://localhost:8080 if the environment variable NCWMS_BASE
# is not in the shell from which the entrypoint.sh script is called.
ARG NCWMS_BASE
ENV NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
RUN if [ $USE_NCWMS = "true" ];then echo "NCWMS_BASE: {$NCWMS_BASE}"; fi


ARG DEVELOPER_MODE
ENV DEVELOPER_MODE=${DEVELOPER_MODE:-"false"}
RUN if [ $DEVELOPER_MODE = "true" ];then echo "DEVELOPER_MODE: ENABLED"; else echo "DEVELOPER_MODE: DISABLED"; fi

#Get mirrorlist before running yum
#RUN cd /etc/yum.repos.d/
#RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-*
#RUN sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-*

################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
# RUN set -e && dnf update  -y
#TODO: prob don't need reinstallpython3.11 here, can use existing 3.12 in image
RUN set -e && dnf install -y python3.11 \
    && python3 --version 

RUN set -e && dnf install -y make curl unzip which autoconf automake emacs vim jq \
    && dnf install -y diffutils \
    && dnf install -y procps \
    && dnf install -y git bc valgrind gdb \
    && dnf install -y java-11-openjdk-devel
# Temporary Hack to fix broken OpenJDK-11.0.20.0.8-2
RUN set -e && dnf install -y tzdata-java

RUN set -e && dnf clean all
RUN set -e && which diff


################################################################
# Set up BES
#
# BES is already installed by definition on the base image, but 
# we need to do some final installation steps that would otherwise
# be handled by RPM installation

RUN echo "besdaemon is here: "`which besdaemon` \
    && echo "whoami: "`whoami`

# Add besd service to start at boot
RUN cp ${PREFIX}/etc/rc.d/init.d/besd /etc/rc.d/init.d/besd \
    && chkconfig --add besd \
    && ldconfig
RUN chkconfig --list | grep besd \
    && echo "whoami: "`whoami`

# # Add bes group and user (previously constructed via rpm installation)
# RUN getent group bes >/dev/null || groupadd -r bes
# RUN getent passwd bes >/dev/null || \
#     useradd -r -g bes -d /var/log/bes -s /sbin/nologin -c "BES daemon" bes

# # Instead of rpm post:
# RUN cp ./usr/local/etc/rc.d/init.d/besd /etc/rc.d/init.d/besd
# RUN chkconfig --add besd \
#     && ldconfig

# More rpm-adapting hijinks
# Adapted from bes/spec.all_static.in
# Default macros: https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/
RUN sed -i.dist -e 's:=/tmp:=/var/cache/bes:' \
    -e 's:=.*/bes.log:=/var/log/bes/bes.log:' \
    -e 's:=.*/lib/bes:=$PREFIX/lib/bes:' \
    -e 's:=.*/share/bes:=$PREFIX/share/bes:' \
    # -e 's:=.*/share/hyrax:=/usr/share/hyrax:' \
    # -e 's:=/full/path/to/serverside/certificate/file.pem:=/etc/pki/bes/cacerts/file.pem:' \
    # -e 's:=/full/path/to/serverside/key/file.pem:=/etc/pki/bes/public/file.pem:' \
    # -e 's:=/full/path/to/clientside/certificate/file.pem:=/etc/pki/bes/cacerts/file.pem:' \
    # -e 's:=/full/path/to/clientside/key/file.pem:=/etc/pki/bes/public/file.pem:' \
    -e 's:=user_name:='"$USER"':' \
    -e 's:=group_name:='"$USER"':' \
    $PREFIX/etc/bes/bes.conf \
    && mkdir -p "/var/log/bes/" \
    && sudo chown -R $USER:$USER "/var/log/bes/"

# RUN chown -R bes /usr/local/etc/bes \
#     /usr/local/share/bes \
#     /usr/local/include/bes \
#     /usr/local/lib/bes \
#     /usr/local/var/run/bes

################################################################
# Install and Setup Tomcat
#
# Make tomcat user and group
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e && useradd -m -U -d /home/tomcat -s /bin/false tomcat
#
# Install the Tomcat package that should have been copied into
# the root directory prior to this layer.
#
RUN set -e \
    && tar -xvf "/${TOMCAT_DISTRO}.tar.gz" -C /home/tomcat >&2 \
    && ln -s /home/tomcat/${TOMCAT_DISTRO} /usr/share/tomcat >&2 \
    && ln -s /home/tomcat/${TOMCAT_DISTRO} /tomcat >&2 \
    && rm -rvf /usr/share/tomcat/webapps/* >&2 \
    && mkdir -p /var/log/tomcat \
    && chown -R tomcat:tomcat /var/log/tomcat /home/tomcat
COPY tomcat.service /etc/systemd/system/tomcat.service
RUN set -e && systemctl enable tomcat
#RUN firewall-cmd --add-port 8080/tcp --permanent
#RUN firewall-cmd --reload

ENV CATALINA_HOME=/usr/share/tomcat
ENV PATH=$CATALINA_HOME/bin:$PATH
RUN set -e && echo "CATALINA_HOME: ${CATALINA_HOME}" >&2

# Install our modified server.xml so that the server compresses responses.
COPY tomcat9-server.xml /
RUN set -e \
    && mv /tomcat9-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml \
    && echo "Cleaning up Tomcat distribution files..." >&2 \
    && rm -fv "/${TOMCAT_DISTRO}.tar.gz"

################################################################
# Install the OLFS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

RUN echo "Installing the latest olfs distribution (${OLFS_VERSION})." >&2
RUN set -e \
    && echo "working_dir: "`pwd`  >&2 \
    && ls -l . \
    && tar -C ${ROOT} -xzvf /${OLFS_DISTRO}.tgz \
    && ls -l ${ROOT} \
    && echo "Unpacking warfile..."  >&2 \
    && mkdir -p $(readlink -f ${CATALINA_HOME})/webapps/${DEPLOYMENT_CONTEXT}/ \
    && unzip -o ${ROOT}/${OLFS_DISTRO}/opendap.war -d ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/ \
    && echo "Cleaning up."  >&2 \
    && rm -rf ${ROOT}/${OLFS_DISTRO} ./${OLFS_DISTRO}.tgz

RUN set -e \
    && echo "Installing the latest dynamic robots.txt distribution (${OLFS_VERSION})."  >&2 \
    && ls -l ./robots* \
    && tar -C ${ROOT} -xzf ./${ROBOTS_DISTRO}.tgz \
    && ls -l ${ROOT}/${ROBOTS_DISTRO} \
    && echo "Unpacking dynamic robots.txt warfile..."  >&2 \
    && unzip -o ${ROOT}/${ROBOTS_DISTRO}/ROOT.war -d ${CATALINA_HOME}/webapps/ROOT/ \
    && echo "Cleaning up dynamic robots.txt snapshot..."  >&2 \
    && rm -rf ${ROOT}/${ROBOTS_DISTRO} ${ROBOTS_DISTRO}.tgz \
    && echo "Cleaning up the Hyrax distribution binaries..." \
    && rm -vf /olfs*.tgz /robots*.tgz /apache*

# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs

################################################################
# retrieve and install the ncWMS web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

ARG NCWMS_VERSION
ENV NCWMS_VERSION=${NCWMS_VERSION:-"2.5.2"}
RUN echo "NCWMS_VERSION: ${NCWMS_VERSION}"
ENV NCWMS_WAR_URL="https://github.com/Reading-eScience-Centre/ncwms/releases/download/ncwms-${NCWMS_VERSION}/ncWMS2.war"
RUN echo "NCWMS_WAR_URL: ${NCWMS_WAR_URL}"

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
        mv /tmp/olfs_viewers.xml ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/viewers.xml; \
    else \
        echo "Skipping OLFS/ncWMS confguration installation."; \
    fi

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
    && git clone --depth 1 -v https://github.com/opendap/hyrax_regression_tests ${TEST_INSTALL_DIR} \
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

################################################################
# TEMPORARY
# Grab the cleanup files script for managing orphaned files
# from fileout_netcdf
COPY cleanup_files.sh /
RUN chmod +x /cleanup_files.sh
# TEMPORARY
################################################################


COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8009
EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

USER root

CMD ["-"]
