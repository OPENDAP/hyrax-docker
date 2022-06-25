#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## HYRAX ##################################" >&2
echo "Greetings, I am "`whoami`"." >&2
set -e
#set -x

################################################################################
# Inject one set of credentials into .netrc
# Only touch the .netrc file if all three environment variables are defined
#
if [ -n "${HOST}" ]  &&  [ -n "${USERNAME}" ] &&  [ -n "${PASSWORD}" ]; then
    # machine is a domain name or a ip address, not a URL.
    echo "machine ${HOST}" | sed -e "s_https:__g"  -e "s_http:__g" -e "s+/++g" >> /etc/bes/ngap_netrc
    echo "    login ${USERNAME}"    >> /etc/bes/ngap_netrc
    echo "    password ${PASSWORD}" >> /etc/bes/ngap_netrc
    chown bes:bes /etc/bes/ngap_netrc
    chmod 400 /etc/bes/ngap_netrc
    ls -l /etc/bes/ngap_netrc  >&2
    cat /etc/bes/ngap_netrc >&2
fi
################################################################################


################################################################################
# Inject user-access.xml document to define the servers relationship to
# EDL and the user access rules.
#
echo "CATALINA_HOME: ${CATALINA_HOME}" >&2
user_access_xml_file="/usr/share/tomcat/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf/user-access.xml"
# Test if the user-access.xml env variable is set (by way of not unset) and not empty
if [ -n "${USER_ACCESS_XML}" ] ; then
    echo "${USER_ACCESS_XML}" > ${user_access_xml_file}
    echo "${user_access_xml_file} -" >&2
    cat ${user_access_xml_file} >&2
fi
################################################################################


################################################################################
# Inject BES configuration site.conf document to configure the BES to operate
# in the NGAP environment.
#
bes_site_conf_file="/etc/bes/site.conf"
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if [ -n "${BES_SITE_CONF}" ] ; then
    # echo "${BES_SITE_CONF}" > ${bes_site_conf_file}
    echo "${BES_SITE_CONF}" | sed -e "s+BES.LogName=stdout+BES.LogName=/var/log/bes/bes.log+g" > ${bes_site_conf_file}
    echo "${bes_site_conf_file} - " >&2
    cat ${bes_site_conf_file} >&2
fi
################################################################################


################################################################################
# Inject Tomcat's context.xml configuration document to configure the Tomcat to
# utilize Session Management in the NGAP environment.
#
tomcat_context_xml_file="/usr/share/tomcat/conf/context.xml"
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if [ -n "${TOMCAT_CONTEXT_XML}" ] ; then
    echo "${TOMCAT_CONTEXT_XML}" > ${tomcat_context_xml_file}
    echo "${tomcat_context_xml_file} - " >&2
    cat ${tomcat_context_xml_file} >&2
fi
################################################################################


################################################################################
# Inject an NGAP Cumulus Configuration
# Only amend the /etc/bes/site.conf file if all the necessary environment
# variables are defined
#
#if [ -n "${S3_DISTRIBUTION_ENDPOINT}" ] &&  \
#   [ -n "${S3_REFRESH_MARGIN}" ] && \
#   [ -n "${S3_AWS_REGION}" ] && \
#   [ -n "${S3_BASE_URL}" ]; then
#
#  echo "Amending BES site.conf file." >&2
#  {
#    echo "NGAP.S3.distribution.endpoint.url=${S3_DISTRIBUTION_ENDPOINT}"
#    echo "NGAP.S3.refresh.margin=${S3_REFRESH_MARGIN}"
#    echo "NGAP.S3.region=${S3_AWS_REGION}"
#    echo "NGAP.S3.url.base=${S3_BASE_URL}"
#  } | tee -a "${bes_site_conf_file}" >&2
#fi
################################################################################

export JAVA_HOME="${JAVA_HOME:-/etc/alternatives/jre}"
echo "JAVA_HOME: ${JAVA_HOME}" >&2

export SLEEP_INTERVAL="${SLEEP_INTERVAL:-60}"
echo "SLEEP_INTERVAL: ${SLEEP_INTERVAL} seconds." >&2

export SERVER_HELP_EMAIL="${SERVER_HELP_EMAIL:-not_set}"
echo "SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}" >&2

export FOLLOW_SYMLINKS="${FOLLOW_SYMLINKS:-not_set}"
echo "FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}" >&2

export NCWMS_BASE="${NCWMS_BASE:-https://localhost:8080}"
echo "NCWMS_BASE: ${NCWMS_BASE}" >&2

export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-<not set>}"
echo "AWS_SECRET_ACCESS_KEY is ${AWS_SECRET_ACCESS_KEY}" >&2

export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-<not set>}"
echo "AWS_ACCESS_KEY_ID is ${AWS_ACCESS_KEY_ID}" >&2

export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-<not set>}"
echo "AWS_DEFAULT_REGION is ${AWS_DEFAULT_REGION}" >&2

debug=false;

while getopts "de:sn:" opt; do
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
      export debug=true
      echo "Debug is enabled" >&2
      ;;
    k)
      export AWS_SECRET_ACCESS_KEY="${OPTARG}"
      echo "Found command line value for AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}" >&2;
      ;;
    i)
      export AWS_ACCESS_KEY_ID="${OPTARG}"
      echo "Found command line value for AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}" >&2;
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

if test "${debug}" = "true" ; then
    echo "CATALINA_HOME: ${CATALINA_HOME}"  >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
fi

DEFAULT_CONF_DIR="${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf"
VIEWERS_XML="${DEFAULT_CONF_DIR}/viewers.xml"
if test "${debug}" = "true" ; then
    echo "NCWMS: Using NCWMS_BASE: ${NCWMS_BASE}"  >&2
    echo "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)."  >&2
    ls -l "${VIEWERS_XML}" >&2
fi

if test -f "${VIEWERS_XML}"; then
    sed -i "s+@NCWMS_BASE@+${NCWMS_BASE}+g" "${VIEWERS_XML}";
fi

if test "${debug}" = "true" ; then
    echo "${VIEWERS_XML} - "  >&2
    cat "${VIEWERS_XML}" >&2
fi

LOGBACK_XML="${DEFAULT_CONF_DIR}/logback.xml"
NGAP_LOGBACK_XML="${DEFAULT_CONF_DIR}/logback-ngap.xml"
if test "${debug}" = "true" ; then
    cp "${NGAP_LOGBACK_XML}" "${LOGBACK_XML}"
    echo "Enabled Logback (slf4j) debug logging for NGAP."  >&2
    cat "${LOGBACK_XML}"  >&2
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

#-------------------------------------------------------------------------------
# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
/usr/bin/besctl start -d "/dev/null,timing" >&2
status=$?
if test $status -ne 0 ; then
    echo "ERROR: Failed to start BES: $status" >&2
    exit $status
fi
besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `
echo "The BES is UP! pid: $besd_pid" >&2

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

    if test $debug = true ; then
        echo "-------------------------------------------------------------------"  >&2
        date >&2
        echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid" >&2
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
    fi

    tail -f /var/log/bes/bes.log | awk -f beslog2json.awk

done
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

