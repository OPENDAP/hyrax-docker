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
default_interval="60" # minutes
default_log="/var/log/bes/nc_cleanup.log"

if test -n "${verbose}"; then echo "##########################################################"; fi
if test -n "${verbose}"; then echo "# $0"; echo "#"; fi


TARGET_DIR="${1:-$default_dir}"
if test -n "${verbose}"; then echo "#   TARGET_DIR: ${TARGET_DIR}"; fi

INTERVAL="${2:-$default_interval}" # minutes
if test -n "${verbose}"; then echo "#     INTERVAL: ${INTERVAL}m"; fi

CLEANUP_LOG="${3:-$default_log}"
if test -n "${verbose}"; then echo "#  CLEANUP_LOG: ${CLEANUP_LOG}"; fi

SLEEP_TIME=$(echo "${INTERVAL}*60" | bc)
if test -n "${verbose}"; then echo "#   SLEEP_TIME: ${SLEEP_TIME}s"; fi
if test -n "${verbose}"; then echo "#"; fi


while true 
do
    orphaned_files=$(find ${TARGET_DIR} -type f -mmin ${INTERVAL})
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

