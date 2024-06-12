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

ARG TOMCAT_VERSION
ENV TOMCAT_VERSION ${TOMCAT_VERSION:-"9.0.64"}
RUN echo "TOMCAT_VERSION: ${TOMCAT_VERSION}"
ENV TOMCAT_DISTRO="apache-tomcat-${TOMCAT_VERSION}"
COPY "${TOMCAT_DISTRO}.tar.gz" /
RUN ls -l /apache-tomcat-*  >&2

ARG HYRAX_VERSION
ENV HYRAX_VERSION=${HYRAX_VERSION:-"snapshot"}
RUN echo "HYRAX_VERSION: ${HYRAX_VERSION}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"libdap-${LIBDAP_VERSION}.el8.x86_64.rpm"}
RUN echo "LIBDAP_RPM: ${LIBDAP_RPM}"
COPY ${LIBDAP_RPM} libdap-devel-* libdap-debuginfo-* /
RUN ls -l /libdap-*  >&2

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"bes-${BES_VERSION}.static.el8.x86_64.rpm"}
RUN echo "BES_RPM: ${BES_RPM}"
COPY ${BES_RPM} bes-devel-* bes-debuginfo-* /
RUN ls -l /bes-* >&2

ARG BUILD_DMRPP_VERSION
ENV BUILD_DMRPP_VERSION=${BUILD_DMRPP_VERSION:-"snapshot"}
RUN echo "BUILD_DMRPP_VERSION: ${BUILD_DMRPP_VERSION}"

ARG BUILD_DMRPP_DISTRO
ENV BUILD_DMRPP_DISTRO=${BUILD_DMRPP_DISTRO:-"build_dmrpp-${BUILD_DMRPP_VERSION}-webapp"}
RUN echo "BUILD_DMRPP_DISTRO: ${BUILD_DMRPP_DISTRO}"
COPY ${BUILD_DMRPP_DISTRO}.tgz /${BUILD_DMRPP_DISTRO}.tgz

ARG DEPLOYMENT_CONTEXT
ENV DEPLOYMENT_CONTEXT=${DEPLOYMENT_CONTEXT:-"build_dmrpp"}
RUN echo "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"


LABEL vendor="OPeNDAP"
LABEL org.opendap.hyrax.version=${HYRAX_VERSION}
LABEL org.opendap.hyrax.release-date=${RELEASE_DATE}
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

################################################################
# Update and install the needful.
#
# Installing autoconf automake git bc for the tests install. The tests
# are installed in the container but not run until a later stage of the
# Travis build (or at a later time). They need to be part of the container,
# however, to be run, so install them as part of this Dockerfile.
RUN set -e && dnf update  -y
RUN set -e && dnf install -y make curl unzip which autoconf automake emacs vim
RUN set -e && dnf install -y diffutils
RUN set -e && dnf install -y procps
RUN set -e && dnf install -y python3 git bc valgrind gdb
RUN set -e && dnf install -y java-11-openjdk-devel
# Temporary Hack to fix broken OpenJDK-11.0.20.0.8-2
RUN set -e && dnf install -y tzdata-java
# Temporary Hack to add missing Apache Portable Runtime library for Tomcat
RUN set -e && dnf install -y ant
RUN set -e && dnf install -y redhat-rpm-config
RUN set -e && dnf install -y apr-devel
RUN set -e && dnf install -y openssl-devel
#
RUN set -e && dnf clean all
RUN set -e && which diff
#
RUN set -e && python3 -m pip install --upgrade pip
RUN set -e && python3 -m pip install --no-cache-dir awscli



################################################################
# Install the latest libdap snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the libdap rpm: ${LIBDAP_RPM}" \
    && ls -l ./libdap* \
    && dnf -y install ./libdap-*.rpm \
    && rm -f ./${LIBDAP_RPM}

RUN echo "libdap4 is installed."

################################################################
# Install the latest BES snapshot
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "Installing the latest BES rpm: ${BES_RPM}" \
    && ls -l ./bes* \
    && dnf -y install ./bes-*.rpm \
    && rm -f ./${BES_RPM}

RUN echo "besdaemon is here: "`which besdaemon`

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

ENV CATALINA_HOME /usr/share/tomcat
ENV PATH $CATALINA_HOME/bin:$PATH
RUN set -e && echo "CATALINA_HOME: ${CATALINA_HOME}" >&2

# Install our modified server.xml so that the server compresses responses.
COPY tomcat9-server.xml /
RUN set -e \
    && mv /tomcat9-server.xml ${CATALINA_HOME}/conf/server.xml \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/conf/server.xml

RUN set -e \
    && echo "Cleaning up Tomcat distribution files..." >&2 \
    && rm -fv "/${TOMCAT_DISTRO}.tar.gz"

# Install the Tomcat Native-APR library.
#
RUN set -e \
    && export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which javac))))" >&2 \
    && echo $JAVA_HOME >&2 \
    && tar -xvf "/${CATALINA_HOME}/bin/tomcat-native.tar.gz" -C ${CATALINA_HOME}/bin >&2 \
    && cd ${CATALINA_HOME}/bin/tomcat-native-1.3.0-src/native >&2 \
    && ./configure >&2 \
    && make >&2 \
    && make install >&2 \
    && echo "SUCCESS: Tomcat Native-APR Library installed"

ENV CATALINA_OPTS "-Djava.library.path=/usr/local/apr/lib"

# Uninstall Java-1.8.0 installed by Ant
RUN set -e && yum remove -y java-1.8.0-openjdk >&2
RUN set -e && dnf install -y java-11-openjdk-devel >&2
RUN set -e && which java && java -version
################################################################
# Install the build dmr++ web application
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
ENV ROOT=/dev/shm

RUN echo "Installing the latest build_dmrpp distribution (${BUILD_DMRPP_VERSION})." >&2
RUN set -e \
    && echo "working_dir: "`pwd`  >&2 \
    && ls -l . \
    && tar -C ${ROOT} -xzvf ./${BUILD_DMRPP_DISTRO}.tgz \
    && ls -l ${ROOT} \
    && echo "Unpacking warfile..."  >&2 \
    && mkdir -p $(readlink -f ${CATALINA_HOME})/webapps/${DEPLOYMENT_CONTEXT}/ \
    && unzip -o ${ROOT}/${BUILD_DMRPP_DISTRO}/build_dmrpp.war -d ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/ \
    && echo "Cleaning up."  >&2 \
    && rm -rf ${ROOT}/${BUILD_DMRPP_DISTRO} ./${BUILD_DMRPP_DISTRO}.tgz


# Fix ownership and access permissions
RUN set -e \
    && mkdir -p ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chown -R tomcat:tomcat ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs \
    && chmod 700 ${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/logs

################################################################
# Clean up the Hyrax distribution binaries.
#
RUN rm -vf /libdap*.rpm /bes*.rpm /build_dmrpp*.tgz /robots*.tgz /apache*
#
################################################################

################################################################
#
# Retrieve, verify, and install the hyrax_regression_tests
# project
#
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -

# @TODO Write regression tests for build_dmrpp
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
################################################################

RUN ls -l /usr/libexec/


COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8009
EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint does not need root
RUN chown -R bes /etc/bes
USER root

CMD ["-"]

