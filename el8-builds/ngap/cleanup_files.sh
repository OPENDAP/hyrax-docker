#!/bin/bash
#
# This script is meant as a temporary patch to the problem of the
# fileout_netcdf handler leaving behind orphaned temporary files 
# that clog the deployments disk. When we understand and repair
# the issue with fileout_netcdf this script can be removed
# from the distributions.
#
#
verbose=
default_dir="/tmp/hyrax_fonc"
default_interval="60" # minutes
default_log="/var/log/bes/cleanup.log"
BES_TMP_FILES_DIR="/tmp/bes_rr_tmp"

if test -n "${verbose}"; then echo "##########################################################" >&2 ; fi
if test -n "${verbose}"; then echo "# $0" >&2; echo "#" >&2; fi

TARGET_DIR="${1:-$default_dir}"
if test -n "${verbose}"; then echo "#   TARGET_DIR: ${TARGET_DIR}" >&2; fi

INTERVAL="${2:-$default_interval}" # minutes
if test -n "${verbose}"; then echo "#     INTERVAL: ${INTERVAL}m" >&2; fi

CLEANUP_LOG="${3:-$default_log}"
if test -n "${verbose}"; then echo "#  CLEANUP_LOG: ${CLEANUP_LOG}" >&2; fi

SLEEP_TIME=$(echo "${INTERVAL}*60/2" | bc)
if test -n "${verbose}"; then echo "#   SLEEP_TIME: ${SLEEP_TIME}s" >&2; fi
if test -n "${verbose}"; then echo "#" >&2; fi

TARGET_DIRS="${TARGET_DIR} ${BES_TMP_FILES_DIR}"

let pass=0
while true 
do
    let pass+=1
    echo "########################################################################################" >> "${CLEANUP_LOG}"
    echo "# Begin Pass: ${pass} ("$(date)")" >> "${CLEANUP_LOG}"
    for target_dir in ${TARGET_DIRS}
    do
        if test -d ${target_dir};
        then
            orphaned_files=$(find ${target_dir} -type f -mmin +${INTERVAL})
            if test -n "${verbose}"; then echo "orphaned_files: "${orphaned_files} >&2; fi

            if test -n "${orphaned_files}";
            then
                echo "# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -" >> "${CLEANUP_LOG}"
                echo "# Begin cleanup of ${target_dir} ("$(date)")" >> "${CLEANUP_LOG}"
                echo "#" >> "${CLEANUP_LOG}"
                for file in ${orphaned_files}
                do
                    target=$(ls -l "${file}")
                    rm -f "${file}"
                    echo $(date)" removed: ${target}" 2>&1 >> "${CLEANUP_LOG}"
                done
                echo "#" >> "${CLEANUP_LOG}"
                echo "# End cleanup of ${target_dir} ("$(date)")" >> "${CLEANUP_LOG}"
            fi
        fi
    done
    sleep "${SLEEP_TIME}"

done

