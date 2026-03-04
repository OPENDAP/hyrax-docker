#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## HYRAX ##################################" >&2
echo "Greetings, I am "`whoami`" (uid: "`echo ${UID}`")."   >&2
# set -e
# set -x

echo "PythonVersion: "$(python3 --version)

export JAVA_HOME=${JAVA_HOME:-"/etc/alternatives/jre"}
echo "JAVA_HOME: ${JAVA_HOME}" >&2

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
echo "SLEEP_INTERVAL: ${SLEEP_INTERVAL} seconds." >&2

export SERVER_HELP_EMAIL=${SERVER_HELP_EMAIL:-"not_set"}
echo "SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}" >&2

export FOLLOW_SYMLINKS=${FOLLOW_SYMLINKS:-"false"}
echo "FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}" >&2

export NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
echo "NCWMS_BASE: ${NCWMS_BASE}" >&2

# AWS ##########################################################################
echo "${HR2}" >&2
if test -n "${AWS_ACCESS_KEY_ID}"
then
    echo "# AWS_ACCESS_KEY_ID: HAS BEEN SET" >&2
else
    echo "# AWS_ACCESS_KEY_ID: HAS NOT BEEN SET" >&2
fi

if test -n "${AWS_SECRET_ACCESS_KEY}"
then
    echo "# AWS_SECRET_ACCESS_KEY: HAS BEEN SET" >&2
else
    echo "# AWS_SECRET_ACCESS_KEY: HAS NOT BEEN SET" >&2
fi

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
echo "#    AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}" >&2


export DEBUG=${DEBUG:-false}

while getopts "de:sn:i:k:r:" opt; do
  echo "Processing command line opt: ${opt}" >&2
  case $opt in
    e)
      export SERVER_HELP_EMAIL=$OPTARG
      echo "Set server admin contact email to: ${SERVER_HELP_EMAIL}" >&2
      ;;
    s)
      export FOLLOW_SYMLINKS="Yes"
      echo "Set FollowSymLinks to: ${FOLLOW_SYMLINKS}" >&2
      ;;
    n)
      export NCWMS_BASE=$OPTARG
      echo "Set ncWMS public facing service base to : ${NCWMS_BASE}" >&2
      ;;
    d)
      DEBUG=true
      echo "Debug is enabled" >&2
      ;;
    i)
      export AWS_ACCESS_KEY_ID="${OPTARG}"
      echo "Found command line value for AWS_ACCESS_KEY_ID." >&2;
      ;;
    k)
      export AWS_SECRET_ACCESS_KEY="${OPTARG}"
      echo "Found command line value for AWS_SECRET_ACCESS_KEY." >&2;
      ;;
    r)
      export AWS_DEFAULT_REGION="${OPTARG}"
      echo "Found command line value for AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}" >&2;
      ;;

    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-e xxx] [-n yyy] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]" >&2
      echo " -e xxx where xxx is the email address of the admin contact for the server." >&2
      echo " -s When present causes the BES to follow symbolic links." >&2
      echo " -n yyy where yyy is the protocol, server and port part "  >&2
      echo "    of the ncWMS service (for example http://foo.com:8090)."  >&2
      echo " -d Enables debugging output for this script."  >&2
      echo " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID." >&2
      echo " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY." >&2
      echo " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION." >&2
      echo "EXITING NOW"  >&2
      exit 2
      ;;
  esac
done

if test "${DEBUG}" = "true" ; then
    echo "CATALINA_HOME: ${CATALINA_HOME}"  >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
fi

if test "${DEBUG}" = "true" ; then
    echo "NCWMS: Using NCWMS_BASE: ${NCWMS_BASE}"  >&2
    echo "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)."  >&2
    ls -l "${VIEWERS_XML}" >&2
fi


sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml
if test "${DEBUG}" = "true" ; then
    echo "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml"  >&2
    cat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml >&2
fi

#-------------------------------------------------------------------------------
# modify bes.conf based on environment variables before startup.
#
if test "${SERVER_HELP_EMAIL}" != "not_set" ; then
    echo "Setting Admin Contact To: $SERVER_HELP_EMAIL"
    sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
fi
if test "${FOLLOW_SYMLINKS}" != "not_set" ; then
    echo "Setting BES FollowSymLinks to YES." >&2
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
fi

echo "JAVA VERSION: "
java -version

aws configure list >&2
status=$?
if test $status -ne 0 ; then
    echo "WARNING: Problem with AWS CLI! (status: ${status})" >&2
fi

echo "PythonVersion: "$(python3 --version)
#-------------------------------------------------------------------------------
# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
bes_uid=$(id -u bes)
echo "bes_uid: ${bes_uid}" >&2
bes_gid=$(id -g bes)
echo "bes_gid: ${bes_gid}" >&2

echo "Launching besd..." >&2
/usr/bin/besctl start
status=$?
if test $status -ne 0 ; then
    echo "ERROR: Failed to start BES: $status" >&2
    exit $status
fi
besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `
echo "The besd is UP! [pid: ${besd_pid}]" >&2

#-------------------------------------------------------------------------------
# Start Tomcat process
#
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

# TEMPORARY
/cleanup_files.sh >&2 &
# TEMPORARY

echo "Hyrax Has Arrived..." >&2
echo "--------------------------------------------------------------------" >&2
#-------------------------------------------------------------------------------
while /bin/true; do
    sleep ${SLEEP_INTERVAL}
    echo "Checking Hyrax Operational State..." >&2
    besd_ps=`ps -f $besd_pid`
    BESD_STATUS=$?
    echo "BESD_STATUS: ${BESD_STATUS}" >&2

    tomcat_ps=$(ps -f "${tomcat_pid}")
    TOMCAT_STATUS=$?
    echo "TOMCAT_STATUS: ${TOMCAT_STATUS}" >&2

    if test $BESD_STATUS -ne 0 ; then
        echo "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid" >&2
        echo "The BES daemon appears to have died! Exiting." >&2
        exit 1
    fi
    if test $TOMCAT_STATUS -ne 0 ; then
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
        echo "Tomcat appears to have died! Exiting." >&2
        echo "Tomcat Console Log [BEGIN]" >&2
        cat /var/log/tomcat/console.log >&2
        echo "Tomcat Console Log [END]" >&2
        echo "catalina.out [BEGIN]" >&2
        cat /usr/share/tomcat/logs/catalina.out >&2
        echo "catalina.out [END]" >&2
        echo "localhost.log [BEGIN]" >&2
        cat /usr/share/tomcat/logs/localhost* >&2
        echo "localhost.log [END]" >&2
        exit 2
    fi
    
    if test "${DEBUG}" = "true" ; then
        echo "-------------------------------------------------------------------"  >&2
        date >&2
        echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid" >&2
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
    fi
done
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

