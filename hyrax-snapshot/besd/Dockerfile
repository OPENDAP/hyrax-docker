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
FROM centos:7

ARG RELEASE_DATE
ENV RELEASE_DATE ${RELEASE_DATE:-"unknown"}
RUN echo "RELEASE_DATE: ${RELEASE_DATE}"

# SNAPSHOT URLs
ENV LIBDAP_RPM="s3://opendap.travis.build/libdap-snapshot.el7.x86_64.rpm"
ENV BES_RPM="s3://opendap.travis.build/bes-snapshot.static.el7.x86_64.rpm"

LABEL vendor="OPeNDAP Incorporated"
LABEL org.opendap.besdaemon.version=snapshot
LABEL org.opendap.besdaemon.release-date=RELEASE_DATE
LABEL org.opendap.hyrax.version.is-production="false"

MAINTAINER support@opendap.org

USER root

# Update and install the needful.
RUN set -e \
    && yum -y install \
        which
        awscli \
    && yum -y update \
    && yum clean all

###############################################################
# Retrieve and install the latest libdap snapshot
RUN set -e \
    && echo "Retrieving, and installing libdap snapshot. rpm: $LIBDAP_RPM" \
    && aws --no-sign-request --region=us-east-1 s3 cp ${LIBDAP_RPM}  ./libdap.rpm\
    && ls -l ./libdap* \
    && yum -y install ./libdap.rpm \
    && rm -f libdap.*


###############################################################
# Retrieve and install the latest BES snapshot
RUN set -e \
    && echo "Retrieving, and installing besd snapshot. rpm: $BES_RPM" \
    && aws --no-sign-request --region=us-east-1 s3 cp ${BES_RPM}  ./bes.rpm\
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

