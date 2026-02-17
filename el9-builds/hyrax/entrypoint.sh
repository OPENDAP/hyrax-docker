#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
function loggy(){
    echo  "$@" | awk '{ print "# "$0;}'  >&2
}

loggy "############################## HYRAX ##################################"
loggy "Greetings, I am "`whoami`" (uid: "`echo ${UID}`")."
# set -e
# set -x

echo "PythonVersion: "$(python3 --version)

export JAVA_HOME=${JAVA_HOME:-"/etc/alternatives/jre"}
loggy "JAVA_HOME: $JAVA_HOME"

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
loggy "SLEEP_INTERVAL: $SLEEP_INTERVAL seconds."

export SERVER_HELP_EMAIL=${SERVER_HELP_EMAIL:-"not_set"}
loggy "SERVER_HELP_EMAIL: $SERVER_HELP_EMAIL"

export FOLLOW_SYMLINKS=${FOLLOW_SYMLINKS:-"false"}
loggy "FOLLOW_SYMLINKS: $FOLLOW_SYMLINKS"

export NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
loggy "NCWMS_BASE: $NCWMS_BASE"

# AWS ##########################################################################
loggy "$HR2"
if test -n "$AWS_ACCESS_KEY_ID"
then
    loggy "AWS_ACCESS_KEY_ID: HAS BEEN SET"
else
    loggy "AWS_ACCESS_KEY_ID: HAS NOT BEEN SET"
fi

if test -n "$AWS_SECRET_ACCESS_KEY"
then
    loggy "AWS_SECRET_ACCESS_KEY: HAS BEEN SET"
else
    loggy "AWS_SECRET_ACCESS_KEY: HAS NOT BEEN SET"
fi

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
loggy "       AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"


export DEBUG=${DEBUG:-"true"}
loggy "DEBUG: $DEBUG"

while getopts "de:sn:i:k:r:" opt; do
  loggy "Processing command line opt: $opt"
  case $opt in
    e)
      export SERVER_HELP_EMAIL=$OPTARG
      loggy "Set server admin contact email to: $SERVER_HELP_EMAIL"
      ;;
    s)
      export FOLLOW_SYMLINKS="Yes"
      loggy "Set FollowSymLinks to: $FOLLOW_SYMLINKS"
      ;;
    n)
      export NCWMS_BASE=$OPTARG
      loggy "Set ncWMS public facing service base to : $NCWMS_BASE"
      ;;
    d)
      DEBUG=true
      loggy "Debug is enabled"
      ;;
    i)
      export AWS_ACCESS_KEY_ID="$OPTARG"
      loggy "Found command line value for AWS_ACCESS_KEY_ID.";
      ;;
    k)
      export AWS_SECRET_ACCESS_KEY="$OPTARG"
      loggy "Found command line value for AWS_SECRET_ACCESS_KEY.";
      ;;
    r)
      export AWS_DEFAULT_REGION="$OPTARG"
      loggy "Found command line value for AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION";
      ;;

    \?)
      loggy "Invalid option: -$OPTARG"
      loggy "options: [-e xxx] [-n yyy] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]"
      loggy " -e xxx where xxx is the email address of the admin contact for the server."
      loggy " -s When present causes the BES to follow symbolic links."
      loggy " -n yyy where yyy is the protocol, server and port part "
      loggy "    of the ncWMS service (for example http://foo.com:8090)."
      loggy " -d Enables debugging output for this script."
      loggy " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID."
      loggy " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY."
      loggy " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION."
      loggy "EXITING NOW"
      exit 2
      ;;
  esac
done

if test "$DEBUG" = "true" ; then
    loggy "CATALINA_HOME: $CATALINA_HOME"
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"
fi

if test "${DEBUG}" = "true" ; then
    loggy "NCWMS: Using NCWMS_BASE: $NCWMS_BASE"
    loggy "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)."
    ls -l "$VIEWERS_XML"
fi

sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" "$CATALINA_HOME/webapps/opendap/WEB-INF/conf/viewers.xml"
if test "$DEBUG" = "true" ; then
    loggy "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml"
    loggy "$(cat "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml")"
fi

#-------------------------------------------------------------------------------
# modify bes.conf based on environment variables before startup.
#
if test "$SERVER_HELP_EMAIL" != "not_set" ; then
    loggy "Setting Admin Contact To: $SERVER_HELP_EMAIL"
    sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" "/etc/bes/bes.conf"
fi
if test "$FOLLOW_SYMLINKS" != "not_set" ; then
    loggy "Setting BES FollowSymLinks to YES."
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" "/etc/bes/bes.conf"
fi

loggy "JAVA VERSION: $(java -version)"

loggy "Checking AWS CLI..."
set +e
which aws
status=$?
set -e
if test $status -ne 0
then
    loggy "WARNING: AWS CLI not detected on PATH, may not be installed."
else
    aws configure list
    status=$?
    if test $status -ne 0 ; then
        loggy "WARNING: Problem with AWS CLI configuration! (status: $status)"
    fi
fi

loggy "PythonVersion: $(python3 --version)"
#-------------------------------------------------------------------------------
# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
bes_uid=$(id -u bes)
loggy "bes_uid: $bes_uid"
bes_gid=$(id -g bes)
loggy "bes_gid: $bes_gid"

loggy "Launching besd..."
/usr/bin/besctl start
status=$?
if test $status -ne 0 ; then
    loggy "ERROR: Failed to start BES: $status"
    exit $status
fi
besd_pid=$(ps aux | grep "/usr/bin/besdaemon" | grep -v grep | awk '{print $2;}' - )
loggy "The besd is UP! [pid: $besd_pid]"

#-------------------------------------------------------------------------------
# Start Tomcat process
#
export OLFS_CONF="${CATALINA_HOME}/webapps/opendap/WEB-INF/conf"
# mv ${OLFS_CONF}/logback.xml ${OLFS_CONF}/logback.xml.OFF
loggy "Starting Tomcat..."
#systemctl start tomcat
"$CATALINA_HOME"/bin/startup.sh > /var/log/tomcat/console.log  2>&1 &
status=$?
tomcat_pid=$! # The $! is the PID of the most recently executed background command.
if test $status -ne 0 ; then
    loggy "ERROR: Failed to start Tomcat: $status"
    exit $status
fi
# When we launch tomcat the initial pid gets "retired" because it spawns a
# secondary processes.
initial_pid=$tomcat_pid
loggy "Tomcat started, initial pid: $initial_pid"
while test $initial_pid -eq $tomcat_pid
do
    sleep 1
    tomcat_ps=$(ps aux | grep tomcat | grep -v grep)
    loggy "tomcat_ps: $tomcat_ps"
    tomcat_pid=$(echo "$tomcat_ps" | awk '{print $2}')
    loggy "tomcat_pid: $tomcat_pid"
done
# New pid and we should be good to go.
loggy "Tomcat is UP! pid: $tomcat_pid"

# TEMPORARY
/cleanup_files.sh >&2 &
# TEMPORARY

sleep -h

loggy "Hyrax Has Arrived..."
loggy "--------------------------------------------------------------------"
#-------------------------------------------------------------------------------
while /bin/true; do
    loggy "SLEEP_INTERVAL: '$SLEEP_INTERVAL'"
    sleep $SLEEP_INTERVAL
    loggy "Checking Hyrax Operational State..."
    besd_ps="$(ps -f "$besd_pid")"
    BESD_STATUS=$?
    loggy "BESD_STATUS: ${BESD_STATUS}"

    tomcat_ps="$(ps -f "${tomcat_pid}")"
    TOMCAT_STATUS=$?
    loggy "TOMCAT_STATUS: $TOMCAT_STATUS"

    if test $BESD_STATUS -ne 0 ; then
        loggy "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid"
        loggy "The BES daemon appears to have died! Exiting."
        exit 1
    fi
    if test $TOMCAT_STATUS -ne 0 ; then
        loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
        loggy "Tomcat appears to have died! Exiting."
        loggy "Tomcat Console Log [BEGIN]"
        loggy "$(cat /var/log/tomcat/console.log)"
        loggy "Tomcat Console Log [END]"
        loggy "catalina.out [BEGIN]"
        loggy "$(cat /usr/share/tomcat/logs/catalina.out)"
        loggy "catalina.out [END]"
        loggy "localhost.log [BEGIN]"
        loggy "$(cat /usr/share/tomcat/logs/localhost*)"
        loggy "localhost.log [END]"
        exit 2
    fi
    
    if test "${DEBUG}" = "true" ; then
        loggy "-------------------------------------------------------------------"
        date
        loggy "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid"
        loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
    fi
done
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

