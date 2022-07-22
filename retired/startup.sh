#!/bin/bash
#
#
# Super simple launcher script for hyrax-docker that relies on the "prefix" environment variable
# to locate log file output and data inputs for the BES.
#

# Run the besd container 
docker run -itd -p 10022:10022 -v $prefix/share/hyrax:/usr/share/hyrax --name=besd bes-3.18.0-static

# Run the OLFS container and "link" it to the besd container this allows the OLFS to make a network connection
# to the besd container
mkdir -p $prefix/var/olfs_logs
docker run -itd -p 8080:8080 -v $prefix/var/olfs_logs:/usr/local/tomcat/webapps/opendap/WEB-INF/conf/logs --link besd --name=olfs olfs-1.16.3 

