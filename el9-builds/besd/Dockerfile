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
FROM rockylinux:9
ENV HR="###############################################################################################################"
ENV HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
ENV TARGET_OS="el9"
ENV ARCH="x86_64"

RUN echo "$HR"
RUN echo "# BEGIN - besd docker build"
# rocky9 comes with python 3.9 by default, and replacing it seems problematic at best.
RUN echo "# Python Version: $(python3 --version)"

ENV dnf_runtime_packages="which unzip procps bc"
RUN echo "# dnf_runtime_packages: $dnf_runtime_packages"

ENV dnf_developer_tools_packages="emacs vim awscli jq gdb valgrind"
RUN echo "# dnf_developer_tools_packages: $dnf_developer_tools_packages"

ARG RELEASE_DATE
ENV RELEASE_DATE="${RELEASE_DATE:-$(date +%s)}"
RUN echo "RELEASE_DATE: $RELEASE_DATE"

ARG LIBDAP_VERSION
ENV LIBDAP_VERSION=${LIBDAP_VERSION:-"snapshot-$TARGET_OS"}
RUN echo "LIBDAP_VERSION: $LIBDAP_VERSION"

ARG LIBDAP_RPM
ENV LIBDAP_RPM=${LIBDAP_RPM:-"libdap-$LIBDAP_VERSION.$TARGET_OS.x86_64.rpm"}
RUN echo "LIBDAP_RPM: $LIBDAP_RPM"
COPY "$LIBDAP_RPM" "/$LIBDAP_RPM"

ARG BES_VERSION
ENV BES_VERSION=${BES_VERSION:-"snapshot-$TARGET_OS"}
RUN echo "BES_VERSION: $BES_VERSION"

ARG BES_RPM
ENV BES_RPM=${BES_RPM:-"bes-$BES_VERSION.static.$TARGET_OS.x86_64.rpm"}
RUN echo "BES_RPM: $BES_RPM"
COPY "$BES_RPM" "/$BES_RPM"


LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.besdaemon.version="$BES_VERSION"
LABEL org.opendap.besdaemon.release-date="$RELEASE_DATE"
LABEL org.opendap.hyrax.version.is-production="false"
LABEL org.opencontainers.image.authors="support@opendap.org"

USER root

######################################################################
# Update the OS and create a handy executable shell scipt to simplify
# the installation of the (not as yet installed) but super useful
# developer tools packages :) ndp
RUN set -e \
    && dnf update -y \
    && dnf install -y $dnf_runtime_packages \
    && echo "#!/bin/bash" > /install-dev-tools \
    && echo "dnf install -y $dnf_developer_tools_packages" > /install-dev-tools \
    && chmod 755 /install-dev-tools

################################################################
# Install the libdap rpm
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Installing the libdap rpm: $LIBDAP_RPM" >&2 \
    && ls -l ./libdap* \
    && dnf -y install ./libdap-*.rpm \
    && echo "# The 'dnf install' command exited with status: $?" >&2 \
    && rm -f "./$LIBDAP_RPM" \
    && dnf clean all \
    && echo "# libdap4 is installed." >&2 \
    && echo "$HR" >&2

################################################################
# Install the the BES
# besd, besdaemon, beslistener, besctl, besstandalone, bescmdline
#  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
RUN set -e \
    && echo "$HR" >&2 \
    && echo "# Installing the BES rpm: $BES_RPM" >&2 \
    && ls -l ./bes* \
    && dnf -y install ./bes-*.rpm \
    && echo "# The 'dnf install' command exited with status: $?" >&2 \
    && rm -f "./$BES_RPM" \
    && dnf clean all \
    && echo "# besdaemon is here: $(which besdaemon)" >&2 \
    && echo "#      besdaemon -v: '$(besdaemon -v)'" >&2 \
    && echo "$HR" >&2


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

