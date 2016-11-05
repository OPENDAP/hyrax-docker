#!/bin/bash
#set -exv
set -e
echo "$@"

if [ "${1:0:1}" = '-' ]; then
	set -- catalina.sh run
fi

if [ "$1" = 'catalina.sh' ]; then

	# modify viewers.xml.conf based on environment variable before startup
	if [ "$OLFS_WMS_VIEWERS_HOSTPORT" ]; then
		sed -i "s/OLFS_WMS_VIEWERS_HOSTPORT/$OLFS_WMS_VIEWERS_HOSTPORT/" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml
	fi

	exec gosu tomcat "$@"
fi

exec "$@"
