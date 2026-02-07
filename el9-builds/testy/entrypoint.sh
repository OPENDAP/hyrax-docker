#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

echo "############################## HYRAX ##################################" >&2
echo "Greetings, I am "`whoami`" (uid: "`echo ${UID}`")."   >&2
# set -e
# set -x

echo "Starting..." >&2
echo "--------------------------------------------------------------------" >&2
#-------------------------------------------------------------------------------
export lap=0
while /bin/true; do
    sleep 10
    echo "lap: $lap"
    (( lap++ ))
done

