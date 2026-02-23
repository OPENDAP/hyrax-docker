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
ARG BES_IMAGE_TAG
FROM ${BES_IMAGE_TAG:-"rockylinux:8"}

ARG BES_IMAGE_TAG
RUN if [ -z "$BES_IMAGE_TAG" ]; then \
        echo "Error: Non-empty BES_IMAGE_TAG must be specified. Exiting."; \
        exit 1; \
    fi

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

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
        echo "Error: Expected LIBDAP_VERSION `${LIBDAP_VERSION}`, found version `${LIBDAP_VERSION_FOUND}`. Exiting."; \
        exit 1; \
    fi

LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.besdaemon.version=${BES_VERSION}
LABEL org.opendap.besdaemon.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root
WORKDIR /

# Update and install the needful.
RUN set -e && dnf install -y python3.11 \
    && python3 --version \
#
# RUN set -e
    && dnf install -y which bc emacs vim \
    && dnf install -y procps \
    && dnf update -y \
    && dnf clean all

RUN set -e && curl -sS https://bootstrap.pypa.io/get-pip.py | python3 \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install --no-cache-dir awscli

# Set up BES
#
# BES is already installed on the base image, but
# we need to do some additional configuration (to match what was
# previously handled by bes RPM installation)

# Add besd service to start at boot
RUN cp ${PREFIX}/etc/rc.d/init.d/besd /etc/rc.d/init.d/besd \
    && chkconfig --add besd \
    && ldconfig \
    && chkconfig --list | grep besd \
    && echo "whoami: "`whoami` \
    && echo "besdaemon is here: "`which besdaemon`

# Adapted from bes/spec.all_static.in
# Default macros: https://docs.fedoraproject.org/en-US/packaging-guidelines/RPMMacros/
RUN sed -i.dist \
    -e 's:=.*/bes.log:=/var/log/bes/bes.log:' \
    -e 's:=.*/lib/bes:='"$PREFIX"'/lib/bes:' \
    -e 's:=.*/share/bes:='"$PREFIX"'/share/bes:' \
    -e 's:=.*/share/hyrax:='"$PREFIX"'/share/hyrax:' \
    # -e 's:=/full/path/to/serverside/certificate/file.pem:=/etc/pki/bes/cacerts/file.pem:' \
    # -e 's:=/full/path/to/serverside/key/file.pem:=/etc/pki/bes/public/file.pem:' \
    # -e 's:=/full/path/to/clientside/certificate/file.pem:=/etc/pki/bes/cacerts/file.pem:' \
    # -e 's:=/full/path/to/clientside/key/file.pem:=/etc/pki/bes/public/file.pem:' \
    -e 's:=user_name:='"$USER"':' \
    -e 's:=group_name:='"$USER"':' \
    $PREFIX/etc/bes/bes.conf \
    && mkdir -p "/var/log/bes/" \
    && touch "/var/log/bes/bes.log" \
    && sudo chown -R $USER:$USER "/var/log/bes/"

RUN echo "besdaemon is here: "`which besdaemon`

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 10022
EXPOSE 11002

CMD ["-"]

