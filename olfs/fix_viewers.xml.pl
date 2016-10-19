#!/usr/bin/perl -p -i
use strict;
use warnings;
# this script is intended to make in-place alterations to the viewers.xml shipped with hyrax olfs
# the alterations are to enable Godiva3, including injecting a placeholder for the required
# host:port combination for client access to the WMS service
# an entrypoint will alter the placeholder at container run time
# if the default localhost:8080 is used, the service will only work from a client on localhost
# perl is used to fit in with the thin environment of the docker container (sed seemed too hard)
# the changes as a diff at time of writing are:
my $diff = '
52c52
<     <!-- WebServiceHandler className="opendap.viewers.NcWmsService" serviceId="ncWms" >
---
>     <WebServiceHandler className="opendap.viewers.NcWmsService" serviceId="ncWms" >
59,61c59,61
<         <NcWmsService href="http://localhost:8080/ncWMS/wms" base="/ncWMS/wms" ncWmsDynamicServiceId="lds"/>
<         <Godiva href="/ncWMS/godiva2.html" base="/ncWMS/godiva2.html"/>
<     </WebServiceHandler -->
---
>         <NcWmsService href="OLFS_WMS_VIEWERS_HOSTPORT/ncWMS/wms" base="/ncWMS/wms" ncWmsDynamicServiceId="lds"/>
>         <Godiva href="/ncWMS/Godiva3.html" base="/ncWMS/Godiva3.html"/>
>     </WebServiceHandler>
65d64
< 
';

  s/\<\!-- WebServiceHandler /<WebServiceHandler /;
  s/\<\/WebServiceHandler --\>/<\/WebServiceHandler>/;
  s/localhost:8080/OLFS_WMS_VIEWERS_HOSTPORT/;
  s/godiva2/Godiva3/g;
