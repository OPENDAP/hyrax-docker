#!/bin/bash
#
# This script is meant as a temporary patch to the problem of the
# fileout_netcdf handler leaving behind orphaned temporary files 
# that clog the deployments disk. When we understand and repair
# the issue with fileout_netcdf this script can be removed
# from the distributions.
#
#
verbose="${verbose:-}"
default_dir="/tmp/hyrax_fonc"
default_interval="1h"
default_log="/var/log/bes/nc_cleanup.log"

if test -n "${verbose}"; then echo "##########################################################"; fi
if test -n "${verbose}"; then echo "# $0"; echo "#"; fi


TARGET_DIR="${1:-$default_dir}"
if test -n "${verbose}"; then echo "#   TARGET_DIR: ${TARGET_DIR}"; fi

INTERVAL="${2:-$default_interval}"
if test -n "${verbose}"; then echo "#     INTERVAL: ${INTERVAL}"; fi

CLEANUP_LOG="${3:-$default_log}"
if test -n "${verbose}"; then echo "#  CLEANUP_LOG: ${CLEANUP_LOG}"; fi


SLEEP_TIME=$(echo "${INTERVAL}" | awk '
    BEGIN{ m["s"]=1;m["m"]=60;m["h"]=3600;m["d"]=86400;}
    {
        time=$1;
        units=substr(time,length(time),1);
        #print "m["units"]: "m[units];
        #print "units: "units
        sub(units,"",time);
        #print "time: "time
        sleeptime=m[units]*time;
        print sleeptime;
    }')
if test -n "${verbose}"; then echo "#   SLEEP_TIME: ${SLEEP_TIME}s"; fi
if test -n "${verbose}"; then echo "#"; fi


while true 
do

    orphaned_files=$(find ${TARGET_DIR} -type f -mtime +${INTERVAL})
    if test -n "${verbose}"; then echo "orphaned_files: "${orphaned_files}; fi

    if test -n "${orphaned_files}"; 
    then
        echo "########################################################################################" >> "${CLEANUP_LOG}"
        echo "# "$(date)" BEGIN File Cleanup of ${TARGET_DIR} " >> "${CLEANUP_LOG}"
        for file in ${orphaned_files}
        do
            target=$(ls -l "${file}")
            rm -f "${file}"
            echo $(date)" removed: ${target}" 2>&1 >> "${CLEANUP_LOG}"
        done
        echo "#" >> "${CLEANUP_LOG}"
    fi
    
    sleep "${SLEEP_TIME}"

done

