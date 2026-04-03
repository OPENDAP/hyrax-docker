#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

export BANNER="################################# HYRAX ###########################################"
export HR0="###################################################################################"
export HR1="-----------------------------------------------------------------------------------"
export HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
export prolog="entrypoint.sh -"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "# " prolog " " $0;}'  >&2
}

#loggy "entrypoint.sh  command line: \"$@\""
loggy "$BANNER"
loggy "Greetings, I am $(whoami) (uid: $UID)"
# set -e
# set -x

loggy "PythonVersion: $(python3 --version)"

export JAVA_HOME=${JAVA_HOME:-"/etc/alternatives/jre"}
loggy "JAVA_HOME: $JAVA_HOME"

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
loggy "SLEEP_INTERVAL: ${SLEEP_INTERVAL} seconds."

export SERVER_HELP_EMAIL=${SERVER_HELP_EMAIL:-"not_set"}
loggy "SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}"

export FOLLOW_SYMLINKS=${FOLLOW_SYMLINKS:-"false"}
loggy "FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}"

export NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
loggy "NCWMS_BASE: ${NCWMS_BASE}"

# AWS ##########################################################################
loggy "$HR2"
if test -n "${AWS_ACCESS_KEY_ID}"
then
    loggy "AWS_ACCESS_KEY_ID: HAS BEEN SET"
else
    loggy "AWS_ACCESS_KEY_ID: HAS NOT BEEN SET"
fi

if test -n "${AWS_SECRET_ACCESS_KEY}"
then
    loggy "AWS_SECRET_ACCESS_KEY: HAS BEEN SET"
else
    loggy "AWS_SECRET_ACCESS_KEY: HAS NOT BEEN SET"
fi

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
loggy "   AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"


export DEBUG=${DEBUG:-false}

while getopts "de:sn:i:k:r:" opt; do
  loggy "Processing command line opt: ${opt}"
  case $opt in
    e)
      export SERVER_HELP_EMAIL=$OPTARG
      loggy "Set server admin contact email to: ${SERVER_HELP_EMAIL}"
      ;;
    s)
      export FOLLOW_SYMLINKS="Yes"
      loggy "Set FollowSymLinks to: ${FOLLOW_SYMLINKS}"
      ;;
    n)
      export NCWMS_BASE=$OPTARG
      loggy "Set ncWMS public facing service base to : ${NCWMS_BASE}"
      ;;
    d)
      DEBUG=true
      loggy "Debug is enabled"
      ;;
    i)
      export AWS_ACCESS_KEY_ID="${OPTARG}"
      loggy "Found command line value for AWS_ACCESS_KEY_ID.";
      ;;
    k)
      export AWS_SECRET_ACCESS_KEY="${OPTARG}"
      loggy "Found command line value for AWS_SECRET_ACCESS_KEY.";
      ;;
    r)
      export AWS_DEFAULT_REGION="${OPTARG}"
      loggy "Found command line value for AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}";
      ;;

    \?)
      loggy "Invalid option: -$OPTARG"
      loggy "options: [-e xxx] [-n yyy] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]"
      loggy " -e xxx where xxx is the email address of the admin contact for the server."
      loggy " -s When present causes the BES to follow symbolic links."
      loggy " -n yyy where yyy is the protocol, server and port part "  >&2
      loggy "    of the ncWMS service (for example http://foo.com:8090)."  >&2
      loggy " -d Enables debugging output for this script."  >&2
      loggy " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID."
      loggy " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY."
      loggy " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION."
      loggy "EXITING NOW"  >&2
      exit 2
      ;;
  esac
done

if test "${DEBUG}" = "true" ; then
    loggy "CATALINA_HOME: ${CATALINA_HOME}"  >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
fi

if test "${DEBUG}" = "true" ; then
    loggy "NCWMS: Using NCWMS_BASE: ${NCWMS_BASE}"  >&2
    loggy "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)."  >&2
    ls -l "${VIEWERS_XML}"
fi


sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml
if test "${DEBUG}" = "true" ; then
    loggy "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml"  >&2
    cat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml >&2
fi

#-------------------------------------------------------------------------------
# modify bes.conf based on environment variables before startup.
#
if test "${SERVER_HELP_EMAIL}" != "not_set" ; then
    loggy "Setting Admin Contact To: $SERVER_HELP_EMAIL"
    sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
fi
if test "${FOLLOW_SYMLINKS}" != "not_set" ; then
    loggy "Setting BES FollowSymLinks to YES."
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
fi

loggy "JAVA VERSION: "
java -version

aws configure list >&2
status=$?
if test $status -ne 0 ; then
    loggy "WARNING: Problem with AWS CLI! (status: ${status})"
fi

loggy "PythonVersion: "$(python3 --version)
#-------------------------------------------------------------------------------
# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid

#-------------------------------------------------------------------------------
# We use 'echo' in the following because downstream code is expecting this
# output to be a key value pair, so none of that loggy() stuff
bes_username="$BES_USER"
bes_uid="$(id -u ${bes_username})"
echo "bes_uid: $bes_uid"
bes_gid="$(id -g ${bes_username})"
echo "bes_gid: $bes_gid"

#-------------------------------------------------------------------------------
# Start the BES

# Where is my precious? Is the precious on the path?
BESD="$(which besdaemon)"
status=$?
if test $status -ne 0
then
    loggy "ERROR - Failed to locate besdaemon on the PATH: $PATH"
    exit $status
fi
loggy "The besdaemon is here: $BESD"

# Start using besctl
loggy "Launching besd [uid: $bes_uid gid: $bes_gid]"
/usr/bin/besctl start > ./besctl.log 2>&1
status=$?
loggy "$(cat ./besctl.log)"
if test $status -ne 0; then
  loggy "ERROR: Failed to start BES: $status"
  exit $status
fi

process_list="$(ps aux)"
loggy "process_list via 'ps aux':"
loggy "$process_list"
besd_pid="$(echo "$process_list" | grep "$BESD" | grep -v grep | awk '{print $2;}' -)"
if test -z "$besd_pid"
then
    loggy "ERROR! Failed to acquire a PID for the besdaemon process. The BES did not start. EXITING NOW!"
    exit 1
fi

loggy "The besdaemon is UP! [pid: $besd_pid]"

#-------------------------------------------------------------------------------
# Start Tomcat process
#
export OLFS_CONF="$CATALINA_HOME/webapps/opendap/WEB-INF/conf"
# mv ${OLFS_CONF}/logback.xml ${OLFS_CONF}/logback.xml.OFF
loggy "Starting Tomcat..."
#systemctl start tomcat
$CATALINA_HOME/bin/startup.sh > /var/log/tomcat/console.log 2>&1  &
status=$?
tomcat_pid=$!
if test $status -ne 0 ; then
    loggy "ERROR: Failed to start Tomcat: $status"
    exit $status
fi
# When we launch tomcat the initial pid gets "retired" because it spawns a
# secondary processes.
initial_pid="$tomcat_pid"
loggy "Tomcat started, initial pid: ${initial_pid}"
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

loggy "Hyrax Has Arrived..."
loggy "--------------------------------------------------------------------"
#-------------------------------------------------------------------------------
while /bin/true; do
    sleep $SLEEP_INTERVAL
    loggy "Checking Hyrax Operational State..."
    besd_ps="$(ps -f "$besd_pid")"
    BESD_STATUS=$?
    loggy "BESD_STATUS: $BESD_STATUS"

    tomcat_ps="$(ps -f "$tomcat_pid")"
    TOMCAT_STATUS=$?
    loggy "TOMCAT_STATUS: $TOMCAT_STATUS"

    if test $BESD_STATUS -ne 0 ; then
        loggy "BESD_STATUS: $BESD_STATUS bes_pid: $besd_pid"
        loggy "The BES daemon appears to have died! Exiting."
        exit $BESD_STATUS
    fi
    if test $TOMCAT_STATUS -ne 0 ; then
        loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
        loggy "Tomcat appears to have died! Exiting."
        loggy "Tomcat Console Log [BEGIN]"
        cat /var/log/tomcat/console.log >&2
        loggy "Tomcat Console Log [END]"
        loggy "catalina.out [BEGIN]"
        cat /usr/share/tomcat/logs/catalina.out >&2
        loggy "catalina.out [END]"
        loggy "localhost.log [BEGIN]"
        cat /usr/share/tomcat/logs/localhost* >&2
        loggy "localhost.log [END]"
        exit $TOMCAT_STATUS
    fi
    
    if test "${DEBUG}" = "true" ; then
        loggy "-------------------------------------------------------------------"  >&2
        loggy "$(date)"
        loggy "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid"
        loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
    fi
done
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

