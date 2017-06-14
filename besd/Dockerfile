###
# Dockerfile for Hyrax BES
###

FROM centos:6.8

MAINTAINER ndp@opendap.org

USER root

# Recommended maintenance
RUN \
    yum -y update && \
    yum clean all

ENV HYRAX_VERSION=1.13.4



RUN yum -y install https://www.opendap.org/pub/binary/hyrax-1.13.4/centos-6.x/libdap-3.19.0-1.el6.x86_64.rpm \
                https://www.opendap.org/pub/binary/hyrax-1.13.4/centos-6.x/bes-3.18.0-1.static.el6.x86_64.rpm

COPY entrypoint.sh /
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 10022
EXPOSE 11002

# can't use USER with entrypoint that needs root
# use gosu or, as done, enable bes user write so the entrypoint doe snot need root
RUN  chown -R bes /etc/bes
USER bes

# tunables - to be overridden on command line or in docker-compose or ansible
ENV BES_HELP_EMAIL=help@replaceme
ENV BES_SYMLINKS=Yes
# Yes (hyrax docker default overrides rpm default) or No, for symlinks in /usr/share/hyrax

CMD ["-"]

