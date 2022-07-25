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

# HYRAX VERSION INFO
ENV HYRAX_VERSION=rocky8
ENV LIBDAP_VERSION=3.20.9-68
ENV BES_VERSION=3.20.10-271
ENV RELEASE_DATE=2022-05-05

# RELEASE URLs
# https://www.opendap.org/pub/binary/hyrax-rocky8/libdap-3.20.1-1.el8.x86_64.rpm
# https://www.opendap.org/pub/binary/hyrax-rocky8/bes-3.20.1-1.static.el8.x86_64.rpm

ENV LIBDAP_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/libdap-${LIBDAP_VERSION}.el8.x86_64.rpm"
ENV BES_RPM="https://www.opendap.org/pub/binary/hyrax-${HYRAX_VERSION}/bes-${BES_VERSION}.static.el8.x86_64.rpm"

LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.besdaemon.version=3.20.10-271
LABEL org.opendap.besdaemon.release-date=2022-05-05
LABEL org.opendap.hyrax.version.is-production="true"

MAINTAINER support@opendap.org

USER root

# Update and install the needful.
RUN set -e \
    && dnf -y install \
        which \
        bc \
    && dnf -y update \
    && dnf clean all

# Installs the OPeNDAP security public key.
# TODO: We should get this from a well known key-server instead.
RUN echo "Adding OPeNDAP Public Security Key"
ENV OPENDAP_PUBLIC_KEY_FILE="security_at_opendap.org.pub.asc"
ENV OPENDAP_PUBLIC_KEY_URL="https://www.opendap.org/${OPENDAP_PUBLIC_KEY_FILE}"
RUN set -e \
    && curl -s $OPENDAP_PUBLIC_KEY_URL > $OPENDAP_PUBLIC_KEY_FILE \
    && gpg --import $OPENDAP_PUBLIC_KEY_FILE

###############################################################
# Retrieve, verify, and install Libdap
RUN set -e \
    && echo "Retrieving, verifying, and installing libdap. rpm: $LIBDAP_RPM" \
    && curl -s $LIBDAP_RPM > ./libdap.rpm \
    && curl -s $LIBDAP_RPM.sig > ./libdap.rpm.sig \
    && gpg -v --verify ./libdap.rpm.sig ./libdap.rpm \
    && ls -l ./libdap* \
    && yum -y install ./libdap.rpm \
    && rm -f libdap.*


###############################################################
# Retrieve, verify, and install the BES
RUN set -e \
    && echo "Retrieving, verifying, and installing besd. rpm: $BES_RPM" \
    && curl -s ${BES_RPM} > ./bes.rpm \
    && curl -s ${BES_RPM}.sig > ./bes.rpm.sig \
    && gpg -v --verify ./bes.rpm.sig ./bes.rpm \
    && ls -l ./bes* \
    && yum -y install ./bes.rpm \
    && rm -f bes.*

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

