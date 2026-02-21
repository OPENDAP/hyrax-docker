#!/bin/bash
# This is the entrypoint.sh file for the olfs container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
export debug="false"
export HR0="###################################################################################"
export HR1="-----------------------------------------------------------------------------------"
export HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
export prolog="entrypoint.sh"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "# " prolog " - " $0;}' >&2
}

loggy "############################## OLFS ##################################"
loggy "Greetings, I am $(whoami)."
set -e
#set -x
loggy "PythonVersion: $(python3 --version)"

export SLEEP_INTERVAL="${SLEEP_INTERVAL:-60}"
loggy "SLEEP_INTERVAL: $SLEEP_INTERVAL seconds."

export NCWMS_BASE="${NCWMS_BASE:-"https://localhost:8080"}"
loggy "NCWMS_BASE: $NCWMS_BASE"

while getopts "n:d" opt; do
  case $opt in
    n)
      NCWMS_BASE=$OPTARG
      loggy "Using commandline NCWMS_BASE: $NCWMS_BASE"
      ;;
    d)
      debug=true;
      loggy "Debug is enabled";
      ;;
    \?)
      loggy "Invalid option: -$OPTARG"
      loggy "options: [-n ncwms_base_url] [-d] "
      loggy " -n xxx where xxx is the protocol, server and port part "
      loggy "    of the ncWMS service (for example http://foo.com:8090/)."
      loggy " -d Enables debugging output for this script."
      loggy "EXITING NOW"
      exit 2;
      ;;
  esac
done

if test "$debug" = true ; then
    loggy "CATALINA_HOME: ${CATALINA_HOME}"
    loggy "$(ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin")"
    loggy "NCWMS_BASE: ${NCWMS_BASE}"
    loggy "Setting ncWMS access URLs in viewers.xml (if needed)."
fi

sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml;
if test "$debug" = true ; then
    loggy "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml"
    loggy "$(cat "$CATALINA_HOME/webapps/opendap/WEB-INF/conf/viewers.xml")"
fi

export OLFS_CONF="$CATALINA_HOME/webapps/opendap/WEB-INF/conf"
# mv ${OLFS_CONF}/logback.xml ${OLFS_CONF}/logback.xml.OFF
loggy "Starting Tomcat..."
"$CATALINA_HOME"/bin/startup.sh > /var/log/tomcat/console.log 2>&1 &
status=$?
tomcat_pid=$!
if test $status -ne 0 ; then
    loggy "ERROR: Failed to start Tomcat: $status"
    exit $status
fi
# When we launch tomcat the initial pid gets "retired" because it spawns a
# secondary processes.
initial_pid="$tomcat_pid"
loggy "Tomcat started, initial pid: $initial_pid"
while test $initial_pid -eq $tomcat_pid
do
    sleep 1
    tomcat_ps="$(ps aux | grep tomcat | grep -v grep)"
    loggy "tomcat_ps: $tomcat_ps"
    tomcat_pid="$(loggy $tomcat_ps | awk '{print $2}')"
    loggy "tomcat_pid: $tomcat_pid"
done
# New pid and we should be good to go.
loggy "Tomcat is UP! pid: $tomcat_pid"


while /bin/true; do
    sleep $SLEEP_INTERVAL
    loggy "Checking Hyrax Operational State..."
    tomcat_ps=$(ps -f "$tomcat_pid")
    TOMCAT_STATUS=$?
    loggy "TOMCAT_STATUS: ${TOMCAT_STATUS}"

    TOMCAT_STATUS=$?
    if test $TOMCAT_STATUS -ne 0 ; then
        loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
        loggy "Tomcat appears to have died! Exiting."
        loggy "Tomcat Console Log [BEGIN]"
        cat /usr/local/tomcat/logs/catalina.out
        loggy "Tomcat Console Log [END]"
        exit -2
    fi
    if test "$debug" = true ; then
        loggy "-------------------------------------------------------------------"
        date
        loggy "TOMCAT_STATUS: $TOMCAT_STATUS  tomcat_pid:$tomcat_pid"
    fi
done

