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
#
ARG BES_CORE_IMAGE_TAG
FROM ${BES_CORE_IMAGE_TAG:-"rockylinux:9"}

ARG BES_CORE_IMAGE_TAG
RUN if [ -z "$BES_CORE_IMAGE_TAG" ]; then \
        echo "Error: Non-empty BES_CORE_IMAGE_TAG must be specified. Exiting."; \
        exit 1; \
    fi

ENV HR="###############################################################################################################"
ENV HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
ENV TARGET_OS="el9"
ENV ARCH="x86_64"

RUN echo "$HR"
RUN echo "# BEGIN - besd docker build"
# rocky9 comes with python 3.9 by default, and replacing it seems problematic at best.
RUN echo "# Python Version: $(python3 --version)"

ENV dnf_runtime_packages="which unzip procps bc chkconfig"
RUN echo "# dnf_runtime_packages: $dnf_runtime_packages"

ENV dnf_developer_tools_packages="emacs vim awscli jq gdb valgrind"
RUN echo "# dnf_developer_tools_packages: $dnf_developer_tools_packages"

ARG RELEASE_DATE
ENV RELEASE_DATE="${RELEASE_DATE:-$(date +%s)}"
RUN echo "RELEASE_DATE: $RELEASE_DATE"

# Fail if requested LIBDAP_VERSION or BES_VERSION do not match installations in base image
ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot-$TARGET_OS"}
RUN LIBDAP_VERSION_FOUND=$(cat libdap_VERSION); \
    if [ "${LIBDAP_VERSION_FOUND}" == "${LIBDAP_VERSION:-missing}" ]; then \
        echo "LIBDAP_VERSION: ${LIBDAP_VERSION}"; \
    else \
        echo "Error: Expected LIBDAP_VERSION \"${LIBDAP_VERSION}\", found version \"${LIBDAP_VERSION_FOUND}\". Exiting."; \
        exit 1; \
    fi

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot-$TARGET_OS"}
RUN BES_VERSION_FOUND=$(cat bes_VERSION); \
    if [ "${BES_VERSION_FOUND}" == "${BES_VERSION:-missing}" ]; then \
        echo "BES_VERSION: ${BES_VERSION}"; \
    else \
        echo "Error: Expected BES_VERSION \"${BES_VERSION}\", found version \"${BES_VERSION_FOUND}\". Exiting."; \
        exit 1; \
    fi

LABEL vendor="OPeNDAP Incorporated"
#LABEL org.opendap.besdaemon.version="$BES_VERSION"
#LABEL org.opendap.besdaemon.release-date="$RELEASE_DATE"
LABEL org.opendap.besd.version="$BES_VERSION"
LABEL org.opendap.besd.release-date="$RELEASE_DATE"
LABEL org.opendap.hyrax.version.is-production="false"
LABEL org.opencontainers.image.authors="support@opendap.org"

USER root
WORKDIR /

######################################################################
# Update the OS and create a handy executable shell scipt to simplify
# the installation of the (not as yet installed) but super useful
# developer tools packages :) ndp
# switch: --disableplugin=system_upgrade,needs_restarting silences
# errors caused by unistalled python bindings in the lean docker
# image.

RUN set -e \
    && dnf --disableplugin=system_upgrade,needs_restarting update -y \
    && dnf install -y $dnf_runtime_packages \
    && echo "#!/bin/bash" > /install-dev-tools \
    && echo "dnf install -y $dnf_developer_tools_packages" > /install-dev-tools \
    && chmod 755 /install-dev-tools \
    && dnf clean all

################################################################
# Test BES installation
#
# Confirm that the besd service starts at boot
RUN echo "besdaemon is here: $(which besdaemon)" \
    && echo "whoami: $(whoami)" \
    && BESD_COUNT=$(chkconfig --list | grep besd) \
    && if [ -z "$BESD_COUNT" ]; then \
        echo "Error: besd service not configured to run on startup. Exiting."; \
        exit 1; \
    fi \
    && besctl start \
    && besctl stop

################################################################

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 10022
EXPOSE 11002

CMD ["-"]

