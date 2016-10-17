#!/bin/bash
#set -exv
set -e
echo "$@"

if [ "${1:0:1}" = '-' ]; then
	set -- beslistener -c /etc/bes/bes.conf \
          -d /var/log/bes/bes.log,-ascii,-besdaemon,-csv,-dap,-ff,-fojson,-fonc,-fong,-gateway,-gdal,-h4,-h5,-nc,-ncml,-ppt,-reader,-server,-usage,-w10n,-www,-xd \
          -i /usr -r /var/run/bes
fi

if [ "$1" = 'beslistener' ]; then

	# modify bes.conf based on environment variable before startup
	if [ "$BES_HELP_EMAIL" ]; then
		sed -i "s/admin.email.address@your.domain.name/$BES_HELP_EMAIL/" /etc/bes/bes.conf
	fi
	if [ "$BES_SYMLINKS" ]; then
		sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
	fi

	#exec gosu bes "$@"
fi

exec "$@"
