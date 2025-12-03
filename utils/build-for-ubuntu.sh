#!/bin/bash

HR="#######################################################################"
###########################################################################
# loggy()
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}

loggy "prefix: $prefix"

cd /root/hyrax-dependencies || exit $?

# make -j16 for-travis 2>&1 | tee $prefix/install/build.log;
