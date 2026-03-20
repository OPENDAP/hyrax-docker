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
ARG BES_CORE_IMAGE_TAG
FROM ${BES_CORE_IMAGE_TAG:-"rockylinux:8"}

ARG BES_CORE_IMAGE_TAG
RUN if [ -z "$BES_CORE_IMAGE_TAG" ]; then \
        echo "Error: Non-empty BES_CORE_IMAGE_TAG must be specified. Exiting."; \
        exit 1; \
    fi

ARG RELEASE_DATE
ENV RELEASE_DATE=${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

ARG BES_VERSION
RUN BES_VERSION_FOUND=$(cat bes_VERSION); \
    if [ "${BES_VERSION_FOUND}" == "${BES_VERSION:-missing}" ]; then \
        echo "BES Version: ${BES_VERSION}"; \
    else \
        echo "Error: Expected BES_VERSION \"${BES_VERSION}\", found version \"${BES_VERSION_FOUND}\". Exiting."; \
        exit 1; \
    fi

ARG LIBDAP_VERSION
RUN LIBDAP_VERSION_FOUND=$(cat libdap_VERSION); \
    if [ "${LIBDAP_VERSION_FOUND}" == "${LIBDAP_VERSION:-missing}" ]; then \
        echo "LIBDAP Version: ${LIBDAP_VERSION}"; \
    else \
        echo "Error: Expected LIBDAP_VERSION \"${LIBDAP_VERSION}\", found version \"${LIBDAP_VERSION_FOUND}\". Exiting."; \
        exit 1; \
    fi

LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.besdaemon.version=${BES_VERSION}
LABEL org.opendap.besdaemon.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"
LABEL org.opencontainers.image.authors="support@opendap.org"

USER root
WORKDIR /

# Update and install the needful.
RUN set -e \
    && dnf update -y \
    && dnf install -y which bc procps \
    && dnf clean all

################################################################
# Test BES installation
#
# Confirm that the besd service starts at boot
RUN echo "besdaemon is here: $(which besdaemon)"
    && echo "whoami: $(whoami)" \
    && BESD_COUNT=$(chkconfig --list | grep besd) \
    && if [ -z "$BESD_COUNT" ]; then \
        echo "Error: besd service not configured to run on startup. Exiting."; \
        exit 1; \
    fi

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 10022
EXPOSE 11002

CMD ["-"]
