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
# Default olfs config
###

#RUN mkdir -p ${CATALINA_HOME}/content/opendap

#COPY files/threddsConfig.xml ${CATALINA_HOME}/content/thredds/threddsConfig.xml

###
# Expose ports
###

EXPOSE 10022
EXPOSE 11002

USER bes

###
# Start container
###

ENTRYPOINT /usr/bin/beslistener -c /etc/bes/bes.conf -d /var/log/bes/bes.log,-ascii,-besdaemon,-csv,-dap,-ff,-fojson,-fonc,-fong,-gateway,-gdal,-h4,-h5,-nc,-ncml,-ppt,-reader,-server,-usage,-w10n,-www,-xd -i /usr -r /var/run/bes

