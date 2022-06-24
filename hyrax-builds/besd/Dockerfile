###############################################################################################
# 
# Dockerfile for besdaemon image
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

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot"}
RUN echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"./libdap-${LIBDAP_VERSION}.el8.x86_64.rpm"}
RUN echo "LIBDAP_RPM: ${LIBDAP_RPM}"
COPY ${LIBDAP_RPM} /${LIBDAP_RPM}

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot"}
RUN echo "BES_VERSION: ${BES_VERSION}"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"./bes-${BES_VERSION}.static.el8.x86_64.rpm"}
RUN echo "BES_RPM: ${BES_RPM}"
COPY ${BES_RPM} /${BES_RPM}


LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.besdaemon.version=${BES_VERSION}
LABEL org.opendap.besdaemon.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

# Update and install the needful.
RUN set -e \
    && dnf -y install which bc python3 emacs vim\
    && dnf -y update \
    && dnf clean all \
    && python3 -m pip install awscli

###############################################################
# Retrieve and install the latest libdap snapshot
RUN set -e \
    && echo "Installing libdap snapshot rpm. ${LIBDAP_RPM}" \
    && ls -l ./libdap* \
    && dnf -y install ./${LIBDAP_RPM} \
    && rm -f ./${LIBDAP_RPM}

###############################################################
# Retrieve and install the latest BES snapshot
RUN set -e \
    && echo "Install the besd rpm ${BES_RPM} " \
    && ls -l ./bes* \
    && dnf -y install ./${BES_RPM} \
    && rm -f ./${BES_RPM}


RUN echo "besdaemon is here: "`which besdaemon`

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint doe snot need root
RUN  chown -R bes /etc/bes
USER root

CMD ["-"]

