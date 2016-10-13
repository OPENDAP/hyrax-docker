#!/bin/bash
#HP=sc-01-cdc.it.csiro.au:8080
HP=${1:-localhost:8080}
sed "s/\$HOSTPORT/$HP/g" olfs/fix_viewers.xml.pl.template > olfs/fix_viewers.xml.pl
