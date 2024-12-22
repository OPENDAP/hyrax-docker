#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
export HRH="########################### HYRAX #################################"
export HRB="########################### besd ##################################"
export HRT="####################### Tomcat/OLFS ################################"
export HR0="###################################################################"
export HR1="#-----------------------------------------------------------------"
export HR2="#-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"

export SYSTEM_ID=${INSTANCE_ID:-"undetermined"}
export LOG_KEY_PREFIX=${LOG_KEY_PREFIX:-"hyrax"}

##########################################################################
#
# Functions
#

##########################################################################
# ologgy() - The old simple loggy.
#
function ologgy() {
  echo "# $*" >&2
}


##########################################################################
# set_log_key_names() - Adds the LOG_KEY_PREFIX to the log key names
#
function set_log_key_names() {
  export TIME_KEY
  TIME_KEY="${LOG_KEY_PREFIX}-time"

  export INSTANCE_ID_KEY
  INSTANCE_ID_KEY="${LOG_KEY_PREFIX}-instance-id"

  export PID_KEY
  PID_KEY="${LOG_KEY_PREFIX}-pid"

  export TYPE_KEY
  TYPE_KEY="${LOG_KEY_PREFIX}-type"

  export MESSAGE_KEY
  MESSAGE_KEY="${LOG_KEY_PREFIX}-message"
}

##########################################################################
# loggy()
# Makes json log records
#
function loggy() {
  echo "{ \"${TIME_KEY}\": "$(date "+%s")"," \
        "\"${INSTANCE_ID_KEY}\": \"${SYSTEM_ID}\"," \
        "\"${PID_KEY}\": "$(echo $$)"," \
        "\"${TYPE_KEY}\": \"start-up\"," \
        "\"${MESSAGE_KEY}\": \"$*\"" \
        "}" >&2
}

##########################################################################
# get_instance_id()
# Try to get the AWS instance-id and if that fails make up a unique one.
#
function get_aws_instance_id() {
  local aws_instance_id_url
  local id_file
  local http_status
  local curl_status
  local instance_id

  aws_instance_id_url="http://169.254.169.254/latest/meta-data/instance-id"
  id_file="./instance-id.txt"
  loggy "Checking for AWS instance-id by requesting: $aws_instance_id_url"

  set +e # This cURL command may fail, and that's ok.
  http_status=$(curl -s -w "%{http_code}" --max-time 5 -o "$id_file" -L "$aws_instance_id_url")
  curl_status=$?
  set -e

  loggy "curl_status: $curl_status"
  loggy "http_status: $http_status"
  if test $curl_status -ne 0 || test $http_status -gt 400; then
    loggy "WARNING! Failed to determine the AWS instance-d by requesting: ${aws_instance_id_url} (curl_status: $curl_status http_status: $http_status)"
    loggy "Inventing an instance-id value."
    instance_id="hyrax-"$(python3 -c 'import uuid; print(str(uuid.uuid4()))')
  else
    instance_id=$(cat $id_file)
  fi
  loggy "Using instance_id: ${instance_id}"
  echo "$instance_id"
}
##########################################################################
##########################################################################
##########################################################################
#
# Execution Begins Here.
#

# Make sure the startup log keys have the correct prefix.
set_log_key_names

#loggy "entrypoint.sh  command line: \"$@\""
loggy "${HRH}"
loggy "Greetings, I am "$(whoami)"."
set -e
#set -x
loggy ""

################################################################################
loggy "${HR1}"
SYSTEM_ID=$(get_aws_instance_id)

################################################################################
loggy "${HR1}"
loggy "     Checking AWS CLI: "
loggy ""
aws configure list 2>&1 | awk '{print "##    "$0;}' >&2
status=$?
if test $status -ne 0; then
  loggy "WARNING: Problem with AWS CLI! (status: ${status})"
fi
loggy ""

################################################################################
loggy "${HR2}"
loggy "         JAVA VERSION: "
java -version 2>&1 | awk '{print "##                       "$0;}' >&2
loggy ""
export JAVA_HOME=${JAVA_HOME:-"/etc/alternatives/jre"}
loggy "            JAVA_HOME: ${JAVA_HOME}"

export CATALINA_HOME=${CATALINA_HOME:-"NOT_SET"}
loggy "        CATALINA_HOME: ${CATALINA_HOME}"

export DEPLOYMENT_CONTEXT=${DEPLOYMENT_CONTEXT:-"ROOT"}
loggy "   DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"

export OLFS_CONF_DIR="${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf"
loggy "        OLFS_CONF_DIR: ${OLFS_CONF_DIR}"

export TOMCAT_CONTEXT_FILE="/usr/share/tomcat/conf/context.xml"
loggy "  TOMCAT_CONTEXT_FILE: ${TOMCAT_CONTEXT_FILE}"

export NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
loggy "           NCWMS_BASE: ${NCWMS_BASE}"

################################################################################
loggy "${HR2}"

if test -n "${AWS_ACCESS_KEY_ID}"; then
  loggy "AWS_ACCESS_KEY_ID: HAS BEEN SET"
else
  loggy "AWS_ACCESS_KEY_ID: HAS NOT BEEN SET"
fi

if test -n "${AWS_SECRET_ACCESS_KEY}"; then
  loggy "AWS_SECRET_ACCESS_KEY: HAS BEEN SET"
else
  loggy "AWS_SECRET_ACCESS_KEY: HAS NOT BEEN SET"
fi

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
loggy "   AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"

################################################################################
loggy "${HR2}"
export NGAP_CERTIFICATE_FILE="/usr/share/tomcat/conf/NGAP-CA-certificate.crt"
loggy "  NGAP_CERTIFICATE_FILE: ${NGAP_CERTIFICATE_FILE}"

export NGAP_CERTIFICATE_CHAIN_FILE="/usr/share/tomcat/conf/NGAP-CA-certificate-chain.crt"
loggy "  NGAP_CERTIFICATE_CHAIN_FILE: ${NGAP_CERTIFICATE_CHAIN_FILE}"

export NGAP_CERTIFICATE_KEY_FILE="/usr/share/tomcat/conf/NGAP-CA-certificate.key"
loggy "  NGAP_CERTIFICATE_KEY_FILE: ${NGAP_CERTIFICATE_KEY_FILE}"

################################################################################
loggy "${HR2}"
export NETRC_FILE="/etc/bes/ngap_netrc"
loggy "           NETRC_FILE: ${NETRC_FILE}"

export BES_SITE_CONF_FILE="/etc/bes/site.conf"
loggy "   BES_SITE_CONF_FILE: ${BES_SITE_CONF_FILE}"

export BES_LOG_FILE="/var/log/bes/bes.log"
loggy "         BES_LOG_FILE: ${BES_LOG_FILE}"

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-60}
loggy "       SLEEP_INTERVAL: ${SLEEP_INTERVAL} seconds."

export SERVER_HELP_EMAIL=${SERVER_HELP_EMAIL:-"not_set"}
loggy "    SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}"

export FOLLOW_SYMLINKS=${FOLLOW_SYMLINKS:-"not_set"}
loggy "      FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}"
loggy ""
loggy "${HR1}"

################################################################################
# Inject one set of credentials into .netrc
# Only modify the .netrc file if all three environment variables are defined
#
if test -n "${HOST}" && test -n "${USERNAME}" && test -n "${PASSWORD}"; then
  loggy "${HR2}"
  loggy "Updating netrc file: ${NETRC_FILE}"
  # machine is a domain name or a ip address, not a URL.
  loggy "machine ${HOST}" | sed -e "s_https:__g" -e "s_http:__g" -e "s+/++g" >>"${NETRC_FILE}"
  loggy "    login ${USERNAME}" >>"${NETRC_FILE}"
  loggy "    password ${PASSWORD}" >>"${NETRC_FILE}"
  chown bes:bes "${NETRC_FILE}"
  chmod 400 "${NETRC_FILE}"
  loggy " "$(ls -l "${NETRC_FILE}") >&2
  # cat "${NETRC_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
################################################################################

################################################################################
# Inject olfs.xml configuration document.
#
# Test if the olfs.xml env variable is set (by way of not unset) and
# not empty and use it's value if present and non-empty.olfs
#
if test -n "${OLFS_XML}"; then
  loggy "${HR2}"
  OLFS_XML_FILE="${OLFS_CONF_DIR}/olfs.xml"
  loggy "Updating OLFS configuration file: ${OLFS_XML_FILE}"
  loggy "${OLFS_XML}" >${OLFS_XML_FILE}
  loggy " "$(ls -l "${OLFS_XML_FILE}") >&2
  # cat "${OLFS_XML_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
################################################################################

################################################################################
# Inject user-access.xml document to define the servers relationship to
# EDL and the user access rules.
#
# Test if the user-access.xml env variable is set (by way of not unset) and
# not empty
#
if test -n "${USER_ACCESS_XML}"; then
  loggy "${HR2}"
  USER_ACCESS_XML_FILE="${OLFS_CONF_DIR}/user-access.xml"
  loggy "Updating OLFS user access controls: ${USER_ACCESS_XML_FILE}"
  loggy "${USER_ACCESS_XML}" >${USER_ACCESS_XML_FILE}
  loggy " "$(ls -l "${USER_ACCESS_XML_FILE}") >&2
  # cat "${USER_ACCESS_XML_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
################################################################################

################################################################################
# Inject BES configuration site.conf document to configure the BES to operate
# in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${BES_SITE_CONF}"; then
  loggy "${HR2}"
  loggy "Updating BES site.conf: ${BES_SITE_CONF_FILE}"
  # loggy "${BES_SITE_CONF}" > ${BES_SITE_CONF_FILE}
  # @TODO THis seems like a crappy hack, we should just change the source file in BitBucket to be correct
  loggy "${BES_SITE_CONF}" | sed -e "s+BES.LogName=stdout+BES.LogName=${BES_LOG_FILE}+g" >${BES_SITE_CONF_FILE}
  loggy " "$(ls -l "${BES_SITE_CONF_FILE}") >&2
  # cat "${BES_SITE_CONF_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
echo "AWS.instance-id=${SYSTEM_ID}" >>"${BES_SITE_CONF_FILE}"
loggy $(tail -1 "${BES_SITE_CONF_FILE}")
################################################################################

################################################################################
# Inject Tomcat's context.xml configuration document to configure the Tomcat to
# utilize Session Management in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${TOMCAT_CONTEXT_XML}"; then
  loggy "${HR2}"
  loggy "Tomcat context.xml file: ${TOMCAT_CONTEXT_FILE}"
  loggy "${TOMCAT_CONTEXT_XML}" >${TOMCAT_CONTEXT_FILE}
  loggy " "$(ls -l "${TOMCAT_CONTEXT_FILE}") >&2
  # cat "${TOMCAT_CONTEXT_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
################################################################################

################################################################################
# Inject Tomcat's NGAP[CA] certificate document to configure the Tomcat to
# utilize SSL/TLS Data-In-Transit in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${NGAP_CERTIFICATE}"; then
  loggy "${HR2}"
  loggy "Tomcat  file: ${NGAP_CERTIFICATE_FILE}"
  loggy "${NGAP_CERTIFICATE}" >${NGAP_CERTIFICATE_FILE}
  loggy " "$(ls -l "${NGAP_CERTIFICATE_FILE}") >&2
  # cat "${NGAP_CERTIFICATE_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
################################################################################

################################################################################
# Inject Tomcat's NGAP[CA] certificate-chain to configure the Tomcat to
# utilize SSL/TLS Data-In-Transit in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${NGAP_CERTIFICATE_CHAIN}"; then
  loggy "${HR2}"
  loggy "Tomcat  file: ${NGAP_CREDENTIALS_CHAIN_FILE}"
  loggy "${NGAP_CERTIFICATE_CHAIN}" >${NGAP_CERTIFICATE_CHAIN_FILE}
  loggy " "$(ls -l "${NGAP_CERTIFICATE_CHAIN_FILE}") >&2
  # cat "${NGAP_CERTIFICATE_CHAIN_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
fi
################################################################################

################################################################################
# Inject Tomcat's NGAP[CA] certificate key to configure the Tomcat to
# utilize SSL/TLS Data-In-Transit in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${NGAP_CERTIFICATE_KEY}"; then
  loggy "${HR2}"
  loggy "Tomcat  file: ${NGAP_CERTIFICATE_KEY_FILE}"
  loggy "${NGAP_CERTIFICATE_KEY}" >${NGAP_CERTIFICATE_KEY_FILE}
  loggy " "$(ls -l "${NGAP_CERTIFICATE_KEY_FILE}") >&2
  # cat "${NGAP_CERTIFICATE_KEY_FILE}" | awk '{print "##    "$0;}' >&2
  loggy ""
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
#    loggy "-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "
#    loggy "Amending BES site.conf file: ${BES_SITE_CONF_FILE}"
#  {
#    loggy "NGAP.S3.distribution.endpoint.url=${S3_DISTRIBUTION_ENDPOINT}"
#    loggy "NGAP.S3.refresh.margin=${S3_REFRESH_MARGIN}"
#    loggy "NGAP.S3.region=${S3_AWS_REGION}"
#    loggy "NGAP.S3.url.base=${S3_BASE_URL}"
#  } | tee -a "${BES_SITE_CONF_FILE}"
#    loggy ""
#fi
################################################################################

################################################################################
#
# Process commandline arguments
#
#
debug=false

while getopts "de:sn:" opt; do
  loggy "Processing command line opt: ${opt}"
  case $opt in
  e)
    export SERVER_HELP_EMAIL=$OPTARG
    loggy "Set SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}"
    ;;
  s)
    export FOLLOW_SYMLINKS="Yes"
    loggy "Set FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}"
    ;;
  n)
    export NCWMS_BASE=$OPTARG
    loggy "Set NCWMS_BASE: ${NCWMS_BASE}"
    ;;
  d)
    export debug=true
    loggy "Debug is enabled"
    ;;
  k)
    export AWS_SECRET_ACCESS_KEY="${OPTARG}"
    loggy "Set AWS_SECRET_ACCESS_KEY"
    ;;
  i)
    export AWS_ACCESS_KEY_ID="${OPTARG}"
    loggy "Set AWS_ACCESS_KEY_ID"
    ;;
  r)
    export AWS_DEFAULT_REGION="${OPTARG}"
    loggy "Set AWS_DEFAULT_REGION"
    ;;

  \?)
    loggy "Invalid option: -$OPTARG"
    loggy "options: [-e xxx] [-n yyy] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]"
    loggy " -e xxx where xxx is the email address of the admin contact for the server."
    loggy " -s When present causes the BES to follow symbolic links."
    loggy " -n yyy where yyy is the protocol, server and port part " >&2
    loggy "    of the ncWMS service (for example http://foo.com:8090)." >&2
    loggy " -d Enables debugging output for this script." >&2
    loggy " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID."
    loggy " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY."
    loggy " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION."
    loggy "EXITING NOW" >&2
    exit 2
    ;;
  esac
done
#
# END Command Line Processing
################################################################################

if test "${debug}" = "true"; then
  loggy "${HR2}"
  loggy "CATALINA_HOME: ${CATALINA_HOME}" >&2
  loggy "   " $(ls -l "${CATALINA_HOME}") >&2
  loggy "CATALINA_HOME/bin: ${CATALINA_HOME}/bin" >&2
  loggy "   " $(ls -l "${CATALINA_HOME}/bin") >&2
  loggy ""
fi

################################################################################
#
#  Configuring NcWMS
#
VIEWERS_XML="${OLFS_CONF_DIR}/viewers.xml"
if test "${debug}" = "true"; then
  loggy "${HR2}"
  loggy "NCWMS: Using NCWMS_BASE: ${NCWMS_BASE}" >&2
  loggy "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)." >&2
  loggy "" $(ls -l "${VIEWERS_XML}") >&2
  loggy ""
fi

if test -f "${VIEWERS_XML}"; then
  sed -i "s+@NCWMS_BASE@+${NCWMS_BASE}+g" "${VIEWERS_XML}"
fi

if test "${debug}" = "true"; then
  loggy "${VIEWERS_XML}: "
  loggy $(cat "${VIEWERS_XML}" | awk '{print "#    "$0;}') >&2
  loggy ""
fi
################################################################################

################################################################################
#
# Configure OLFS debug logging if debug is enabled.
if test "${debug}" = "true"; then
  loggy "${HR2}"
  loggy "Configuring OLFS to debug logging..."
  logback_xml="${OLFS_CONF_DIR}/logback.xml"
  ngap_logback_xml="${OLFS_CONF_DIR}/logback-ngap.xml"
  cp "${ngap_logback_xml}" "${logback_xml}"
  loggy "Enabled Logback (slf4j) debug logging for NGAP." >&2
  loggy $(cat "${logback_xml}" | awk '{print "#    "$0;}') >&2
  loggy "" >&2
fi
################################################################################

################################################################################
#
# modify bes.conf based on environment variables before startup.
#
if test "${SERVER_HELP_EMAIL}" != "not_set"; then
  loggy "${HR2}"
  loggy "Setting Admin Contact To: $SERVER_HELP_EMAIL"
  sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
  loggy "" >&2
fi
if test "${FOLLOW_SYMLINKS}" != "not_set"; then
  loggy "${HR2}"
  loggy "Setting BES FollowSymLinks to YES."
  sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
  loggy ""
fi
################################################################################

#-------------------------------------------------------------------------------
# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
bes_uid=$(id -u bes)
bes_gid=$(id -g bes)
loggy "${HRB}"
loggy "Launching besd [uid: ${bes_uid} gid: ${bes_gid}]"
/usr/bin/besctl start >&2 # dropped debug control -d "/dev/null,timing"  - ndp 10/12/2023
status=$?
if test $status -ne 0; then
  loggy "ERROR: Failed to start BES: $status"
  exit $status
fi
besd_pid=$(ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' -)
loggy "The besd is UP! [pid: ${besd_pid}]"
loggy ""

#-------------------------------------------------------------------------------
# Start Tomcat process
#
loggy "${HRT}"
loggy "Starting tomcat/olfs..."

# mv ${OLFS_CONF_DIR}/logback.xml ${OLFS_CONF_DIR}/logback.xml.OFF
#systemctl start tomcat

${CATALINA_HOME}/bin/startup.sh 2>&1 >/var/log/tomcat/console.log &
status=$?
tomcat_pid=$!
if test $status -ne 0; then
  loggy "ERROR: Failed to start Tomcat: $status"
  exit $status
fi
# When we launch tomcat the initial pid gets "retired" because it spawns a
# secondary processes.
initial_pid="${tomcat_pid}"
loggy "Tomcat started, initial pid: ${initial_pid}"
while test $initial_pid -eq $tomcat_pid; do
  sleep 1
  tomcat_ps=$(ps aux | grep tomcat | grep -v grep)
  loggy "tomcat_ps: ${tomcat_ps}"
  tomcat_pid=$(echo ${tomcat_ps} | awk '{print $2}')
  loggy "tomcat_pid: ${tomcat_pid}"
done
# New pid and we should be good to go.
loggy "Tomcat is UP! pid: ${tomcat_pid}"
loggy ""

# TEMPORARY ###################################################################
/cleanup_files.sh >&2 &

# The old AWKy way
# tail -f "${BES_LOG_FILE}" | awk -f beslog2json.awk &

# The new snakey way.
tail -f "${BES_LOG_FILE}" | ./beslog2json.py --prefix "${LOG_KEY_PREFIX}" &

# TEMPORARY ###################################################################

loggy "Hyrax Has Arrived..."
loggy ""
loggy "${HR1}"
#-------------------------------------------------------------------------------
while /bin/true; do
  sleep ${SLEEP_INTERVAL}
  if test $debug = true; then loggy "Checking Hyrax Operational State..."; fi
  besd_ps=$(ps -f $besd_pid)
  BESD_STATUS=$?
  if test $debug = true; then loggy "BESD_STATUS: ${BESD_STATUS}"; fi
  if test $BESD_STATUS -ne 0; then
    loggy "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid"
    loggy "The BES daemon appears to have died! Exiting."
    exit $BESD_STATUS
  fi

  tomcat_ps=$(ps -f "${tomcat_pid}")
  TOMCAT_STATUS=$?
  if test $debug = true; then loggy "TOMCAT_STATUS: ${TOMCAT_STATUS}"; fi
  if test $TOMCAT_STATUS -ne 0; then
    loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
    loggy "Tomcat appears to have died! Exiting."
    loggy "Tomcat Console Log [BEGIN]"
    loggy $(cat /var/log/tomcat/console.log)
    loggy "Tomcat Console Log [END]"
    loggy "catalina.out [BEGIN]"
    loggy $(cat /usr/share/tomcat/logs/catalina.out)
    loggy "catalina.out [END]"
    loggy "localhost.log [BEGIN]"
    loggy $(cat /usr/share/tomcat/logs/localhost*)
    loggy "localhost.log [END]"
    exit $TOMCAT_STATUS
  fi

  if test $debug = true; then
    loggy "${HR1}" >&2
    date >&2
    loggy "  BESD_STATUS: $BESD_STATUS     besd_pid: $besd_pid"
    loggy "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid: $tomcat_pid"
  fi

done
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
