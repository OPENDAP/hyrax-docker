#!/bin/bash
# This is the entrypoint.sh file for the olfs container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## OLFS ##################################";   >&2
echo "Greetings, I am "`whoami`".";   >&2
set -e
#set -x

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
echo "SLEEP_INTERVAL: ${SLEEP_INTERVAL} seconds." >&2

export NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
echo "NCWMS_BASE: ${NCWMS_BASE}" >&2

debug=false;

while getopts "n:d" opt; do
  case $opt in
    n)
      echo "Setting ncWMS base URL to: $OPTARG" >&2
      NCWMS_BASE=$OPTARG
      ;;
    d)
      debug=true;
      echo "Debug is enabled" >&2;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-n ncwms_base_url] [-d] " >&2
      echo " -n xxx where xxx is the protocol, server and port part " >&2
      echo "    of the ncWMS service (for example http://foo.com:8090/)." >&2
      echo " -d Enables debugging output for this script." >&2
      echo "EXITING NOW" >&2
      exit 2;
      ;;
  esac
done

if test "${debug}" = true ; then
    echo "CATALINA_HOME: ${CATALINA_HOME}" >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
    echo "NCWMS_BASE: ${NCWMS_BASE}" >&2
    echo "Setting ncWMS access URLs in viewers.xml (if needed)." >&2
fi

sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml;
if test "${debug}" = true ; then
    echo "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml" >&2
    cat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml >&2
fi

export OLFS_CONF="${CATALINA_HOME}/webapps/opendap/WEB-INF/conf"
# mv ${OLFS_CONF}/logback.xml ${OLFS_CONF}/logback.xml.OFF
echo "Starting Tomcat..." >&2
#systemctl start tomcat
${CATALINA_HOME}/bin/startup.sh 2>&1 > /var/log/tomcat/console.log &
status=$?
tomcat_pid=$!
if test $status -ne 0 ; then
    echo "ERROR: Failed to start Tomcat: $status" >&2
    exit $status
fi
# When we launch tomcat the initial pid gets "retired" because it spawns a
# secondary processes.
initial_pid="${tomcat_pid}"
echo "Tomcat started, initial pid: ${initial_pid}" >&2
while test $initial_pid -eq $tomcat_pid
do
    sleep 1
    tomcat_ps=$(ps aux | grep tomcat | grep -v grep)
    echo "tomcat_ps: ${tomcat_ps}" >&2
    tomcat_pid=$(echo ${tomcat_ps} | awk '{print $2}')
    echo "tomcat_pid: ${tomcat_pid}" >&2
done
# New pid and we should be good to go.
echo "Tomcat is UP! pid: ${tomcat_pid}" >&2


while /bin/true; do
    sleep ${SLEEP_INTERVAL}
    echo "Checking Hyrax Operational State..." >&2
    tomcat_ps=$(ps -f "${tomcat_pid}")
    TOMCAT_STATUS=$?
    echo "TOMCAT_STATUS: ${TOMCAT_STATUS}" >&2

    TOMCAT_STATUS=$?
    if test $TOMCAT_STATUS -ne 0 ; then
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
        echo "Tomcat appears to have died! Exiting." >&2
        echo "Tomcat Console Log [BEGIN]" >&2
        cat /usr/local/tomcat/logs/catalina.out >&2
        echo "Tomcat Console Log [END]" >&2
        exit -2
    fi
    if test "${debug}" = true ; then
        echo "-------------------------------------------------------------------"
        date
        echo "TOMCAT_STATUS: $TOMCAT_STATUS  tomcat_pid:$tomcat_pid"
    fi
done

