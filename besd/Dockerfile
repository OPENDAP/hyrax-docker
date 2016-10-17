###
# Dockerfile for Hyrax BES
###

FROM centos:6.8

MAINTAINER Gareth.Williams@csiro.au

###
# Usual maintenance
###

USER root

RUN \
    yum -y update && \
    yum clean all

###
# Grab and unzip the OLFS
###

ENV HYRAX_VERSION=1.13.1

RUN yum -y install https://www.opendap.org/pub/binary/hyrax-1.13.1/centos6.6/libdap-3.18.0-1.el6.x86_64.rpm \
                https://www.opendap.org/pub/binary/hyrax-1.13.1/centos6.6/bes-3.17.2-2.static.el6.x86_64.rpm

###
# Expose ports
###

EXPOSE 10022
EXPOSE 11002

#USER bes

###
# Start container
###

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
CMD ["-"]

