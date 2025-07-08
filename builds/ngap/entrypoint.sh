#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
export debug="false"

export SYSTEM_ID=${INSTANCE_ID:-"undetermined"}
export LOG_KEY_PREFIX=${LOG_KEY_PREFIX:-"hyrax-"}
if [[ "$LOG_KEY_PREFIX" != *"-" ]]; then
    LOG_KEY_PREFIX="${LOG_KEY_PREFIX}-"
fi
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
  TIME_KEY="${LOG_KEY_PREFIX}time"

  export INSTANCE_ID_KEY
  INSTANCE_ID_KEY="${LOG_KEY_PREFIX}instance-id"

  export PID_KEY
  PID_KEY="${LOG_KEY_PREFIX}pid"

  export TYPE_KEY
  TYPE_KEY="${LOG_KEY_PREFIX}type"

  export MESSAGE_KEY
  MESSAGE_KEY="${LOG_KEY_PREFIX}message"
}

##########################################################################
# loggy()
# Makes json log records
#
function startup_log() {
  echo "{ \"${TIME_KEY}\": "$(date "+%s")"," \
        "\"${INSTANCE_ID_KEY}\": \"${SYSTEM_ID}\"," \
        "\"${PID_KEY}\": "$(echo $$)"," \
        "\"${TYPE_KEY}\": \"start-up\"," \
        "\"${MESSAGE_KEY}\": "$(echo -n $* | jq -Rsa '.') \
        "}" >&2
}

function heartbeat_log() {
  echo "{ \"${TIME_KEY}\": "$(date "+%s")"," \
        "\"${INSTANCE_ID_KEY}\": \"${SYSTEM_ID}\"," \
        "\"${PID_KEY}\": "$(echo $$)"," \
        "\"${TYPE_KEY}\": \"heartbeat\"," \
        "\"${MESSAGE_KEY}\": "$(echo -n $* | jq -Rsa '.') \
        "}" >&2
}

function error_log() {
  echo "{ \"${TIME_KEY}\": "$(date "+%s")"," \
        "\"${INSTANCE_ID_KEY}\": \"${SYSTEM_ID}\"," \
        "\"${PID_KEY}\": "$(echo $$)"," \
        "\"${TYPE_KEY}\": \"error\"," \
        "\"${MESSAGE_KEY}\": "$(echo -n $* | jq -Rsa '.') \
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
  startup_log "Checking for AWS instance-id by requesting: $aws_instance_id_url"

  set +e # This cURL command may fail, and that's ok.
  http_status=$(curl -s -w "%{http_code}" --max-time 5 -o "$id_file" -L "$aws_instance_id_url")
  curl_status=$?
  set -e

  startup_log "curl_status: $curl_status"
  startup_log "http_status: $http_status"
  if test $curl_status -ne 0 || test $http_status -gt 400; then
    startup_log "WARNING! Failed to determine the AWS instance-d by requesting: ${aws_instance_id_url} (curl_status: $curl_status http_status: $http_status)"
    startup_log "Inventing a random instance-id value."
    instance_id="h-"$(python3 -c 'import uuid; print(str(uuid.uuid4()))')
  else
    instance_id=$(cat $id_file)
  fi
  startup_log "Using instance_id: ${instance_id}"
  echo "$instance_id"
}
##########################################################################
# write_tomcat_logs()
# Writes the last log_lines of the Tomcat logs console.log, catalina.out,
# and the  most recent localhost*.log files as error log messages.
#
function write_tomcat_logs() {
    local log_lines="$1"
    local wait_time="$2"

    error_log "Tomcat Console Log [BEGIN]"
    error_log $(tail --lines $log_lines /var/log/tomcat/console.log)
    error_log "Tomcat Console Log [END]"
    error_log "catalina.out [BEGIN]"
    error_log $(tail --lines $log_lines /usr/share/tomcat/logs/catalina.out)
    error_log "catalina.out [END]"
    error_log "localhost.log [BEGIN]"
    error_log $(tail --lines $log_lines  $(ls -t /usr/share/tomcat/logs/localhost* | head -1))
    error_log "localhost.log [END]"
    sleep $wait_time
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
startup_log "########################### HYRAX #################################"
startup_log "Greetings, I am "$(whoami)"."
set -e
#set -x
startup_log "PythonVersion: "$(python3 --version)

################################################################################
SYSTEM_ID=$(get_aws_instance_id)

################################################################################
startup_log "Checking AWS CLI: "
acl=$(aws configure list 2>&1)
acl_status=$?
startup_log $acl
if test $acl_status -ne 0; then
  startup_log "WARNING: Problem with AWS CLI! (status: ${acl_status})"
fi

################################################################################
startup_log "JAVA VERSION: " $( java -version 2>&1 | sed -e "s/\"//g"; ) # Java version has undesired double quote chars
export JAVA_HOME=${JAVA_HOME:-"/etc/alternatives/jre"}
startup_log "JAVA_HOME: ${JAVA_HOME}"

export CATALINA_HOME=${CATALINA_HOME:-"NOT_SET"}
startup_log "CATALINA_HOME: ${CATALINA_HOME}"

export DEPLOYMENT_CONTEXT=${DEPLOYMENT_CONTEXT:-"ROOT"}
startup_log "DEPLOYMENT_CONTEXT: ${DEPLOYMENT_CONTEXT}"

export OLFS_CONF_DIR="${CATALINA_HOME}/webapps/${DEPLOYMENT_CONTEXT}/WEB-INF/conf"
startup_log "OLFS_CONF_DIR: ${OLFS_CONF_DIR}"

export TOMCAT_CONTEXT_FILE="/usr/share/tomcat/conf/context.xml"
startup_log "TOMCAT_CONTEXT_FILE: ${TOMCAT_CONTEXT_FILE}"

export TOMCAT_REDISSON_FILE="/usr/share/tomcat/conf/redisson.yaml"
startup_log "TOMCAT_REDISSON_FILE: ${TOMCAT_REDISSON_FILE}"

export NCWMS_BASE=${NCWMS_BASE:-"https://localhost:8080"}
startup_log "NCWMS_BASE: ${NCWMS_BASE}"

################################################################################
if test -n "${AWS_ACCESS_KEY_ID}"; then
  startup_log "AWS_ACCESS_KEY_ID: HAS BEEN SET"
else
  startup_log "AWS_ACCESS_KEY_ID: HAS NOT BEEN SET"
fi

if test -n "${AWS_SECRET_ACCESS_KEY}"; then
  startup_log "AWS_SECRET_ACCESS_KEY: HAS BEEN SET"
else
  startup_log "AWS_SECRET_ACCESS_KEY: HAS NOT BEEN SET"
fi

export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION:-"us-west-2"}
startup_log "AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}"

################################################################################
export NGAP_CERTIFICATE_FILE="/usr/share/tomcat/conf/NGAP-CA-certificate.crt"
startup_log "NGAP_CERTIFICATE_FILE: ${NGAP_CERTIFICATE_FILE}"

export NGAP_CERTIFICATE_CHAIN_FILE="/usr/share/tomcat/conf/NGAP-CA-certificate-chain.crt"
startup_log "NGAP_CERTIFICATE_CHAIN_FILE: ${NGAP_CERTIFICATE_CHAIN_FILE}"

export NGAP_CERTIFICATE_KEY_FILE="/usr/share/tomcat/conf/NGAP-CA-certificate.key"
startup_log "NGAP_CERTIFICATE_KEY_FILE: ${NGAP_CERTIFICATE_KEY_FILE}"

################################################################################
export NETRC_FILE="/etc/bes/ngap_netrc"
startup_log "NETRC_FILE: ${NETRC_FILE}"

export BES_SITE_CONF_FILE="/etc/bes/site.conf"
startup_log "BES_SITE_CONF_FILE: ${BES_SITE_CONF_FILE}"

export BES_LOG_FILE="/var/log/bes/bes.log"
startup_log "BES_LOG_FILE: ${BES_LOG_FILE}"

export SLEEP_INTERVAL=${SLEEP_INTERVAL:-10}
startup_log "SLEEP_INTERVAL: ${SLEEP_INTERVAL} seconds."

export SERVER_HELP_EMAIL=${SERVER_HELP_EMAIL:-"not_set"}
startup_log "SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}"

export FOLLOW_SYMLINKS=${FOLLOW_SYMLINKS:-"not_set"}
startup_log "FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}"

################################################################################
# Inject one set of credentials into .netrc
# Only modify the .netrc file if all three environment variables are defined
#
if test -n "${HOST}" && test -n "${USERNAME}" && test -n "${PASSWORD}"; then
  startup_log "Updating netrc file: ${NETRC_FILE}"
  # machine is a domain name or a ip address, not a URL.
  echo "machine ${HOST}" | sed -e "s_https:__g" -e "s_http:__g" -e "s+/++g" >>"${NETRC_FILE}"
  echo "    login ${USERNAME}" >> "${NETRC_FILE}"
  echo "    password ${PASSWORD}" >> "${NETRC_FILE}"
  chown bes:bes "${NETRC_FILE}"
  chmod 400 "${NETRC_FILE}"
  startup_log " "$(ls -l "${NETRC_FILE}")
  # loggy $( cat "${NETRC_FILE}" )
fi
################################################################################

################################################################################
# Inject olfs.xml configuration document.
#
# Test if the olfs.xml env variable is set (by way of not unset) and
# not empty and use it's value if present and non-empty.olfs
#
if test -n "${OLFS_XML}"; then
  OLFS_XML_FILE="${OLFS_CONF_DIR}/olfs.xml"
  startup_log "Updating OLFS configuration file: ${OLFS_XML_FILE}"
  echo "${OLFS_XML}" > ${OLFS_XML_FILE}
  startup_log " "$( ls -l "${OLFS_XML_FILE}" )
  # loggy $( cat "${OLFS_XML_FILE}" )
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
  USER_ACCESS_XML_FILE="${OLFS_CONF_DIR}/user-access.xml"
  startup_log "Updating OLFS user access controls: ${USER_ACCESS_XML_FILE}"
  echo "${USER_ACCESS_XML}" > ${USER_ACCESS_XML_FILE}
  startup_log " "$(ls -l "${USER_ACCESS_XML_FILE}")
  # loggy ( cat "${USER_ACCESS_XML_FILE}" )
fi
################################################################################

################################################################################
# Inject BES configuration site.conf document to configure the BES to operate
# in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${BES_SITE_CONF}"; then
  startup_log "Updating BES site.conf: ${BES_SITE_CONF_FILE}"
  # echo "${BES_SITE_CONF}" > ${BES_SITE_CONF_FILE}
  # @TODO THis seems like a crappy hack, we should just change the source file in BitBucket to be correct
  echo "${BES_SITE_CONF}" | sed -e "s+BES.LogName=stdout+BES.LogName=${BES_LOG_FILE}+g" >${BES_SITE_CONF_FILE}
  startup_log " "$( ls -l "${BES_SITE_CONF_FILE}" )
  # loggy $( cat "${BES_SITE_CONF_FILE}" )
fi
#
# Update site.conf with the instance-id of this system.
echo "AWS.instance-id=${SYSTEM_ID}" >> "${BES_SITE_CONF_FILE}"
startup_log "instance-id in site.conf: "$( tail -1 "${BES_SITE_CONF_FILE}" )
################################################################################

################################################################################
# Inject Tomcat's context.xml configuration document to configure the Tomcat to
# utilize Session Management in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${TOMCAT_CONTEXT_XML}"; then
  startup_log "Writing Tomcat context.xml file: ${TOMCAT_CONTEXT_FILE}"
  echo "${TOMCAT_CONTEXT_XML}" > ${TOMCAT_CONTEXT_FILE}
  startup_log " "$( ls -l "${TOMCAT_CONTEXT_FILE}" )
  # loggy $(cat "${TOMCAT_CONTEXT_FILE}" )
fi
################################################################################

################################################################################
# Inject Tomcat's NGAP[CA] certificate document to configure the Tomcat to
# utilize SSL/TLS Data-In-Transit in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${NGAP_CERTIFICATE}"; then
  startup_log "Writing certificate file: ${NGAP_CERTIFICATE_FILE}"
  echo "${NGAP_CERTIFICATE}" > "${NGAP_CERTIFICATE_FILE}"
  startup_log " "$( ls -l "${NGAP_CERTIFICATE_FILE}" )
  # loggy $(cat "${NGAP_CERTIFICATE_FILE}" )
fi
################################################################################

################################################################################
# Inject Tomcat's NGAP[CA] certificate-chain to configure the Tomcat to
# utilize SSL/TLS Data-In-Transit in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${NGAP_CERTIFICATE_CHAIN}"; then
  startup_log "Writing credentials chain file: ${NGAP_CREDENTIALS_CHAIN_FILE}"
  echo "${NGAP_CERTIFICATE_CHAIN}" > "${NGAP_CERTIFICATE_CHAIN_FILE}"
  startup_log " "$( ls -l "${NGAP_CERTIFICATE_CHAIN_FILE}" )
  # loggy $(cat "${NGAP_CERTIFICATE_CHAIN_FILE}" )
fi
################################################################################

################################################################################
# Inject Tomcat's NGAP[CA] certificate key to configure the Tomcat to
# utilize SSL/TLS Data-In-Transit in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${NGAP_CERTIFICATE_KEY}"; then
  startup_log "Writing key file: ${NGAP_CERTIFICATE_KEY_FILE}"
  echo "${NGAP_CERTIFICATE_KEY}" > "${NGAP_CERTIFICATE_KEY_FILE}"
  startup_log " "$( ls -l "${NGAP_CERTIFICATE_KEY_FILE}" )
  # loggy $(cat "${NGAP_CERTIFICATE_KEY_FILE}" )
fi
################################################################################

################################################################################
# Inject Tomcat's redisson.yaml configuration document to configure the Tomcat to
# utilize Redisson Session Management in the NGAP environment.
#
# Test if the bes.conf env variable is set (by way of not unset) and not empty
if test -n "${TOMCAT_REDISSON_XML}"; then
  startup_log "Writing Tomcat redisson.yaml file: ${TOMCAT_REDISSON_FILE}"
  echo "${TOMCAT_REDISSON_XML}" > ${TOMCAT_REDISSON_FILE}
  startup_log " "$( ls -l "${TOMCAT_REDISSON_FILE}" )
  # loggy $(cat "${TOMCAT_REDISSON_FILE}" )
fi
################################################################################

################################################################################
#
# Process commandline arguments
#
#

while getopts "e:sn:" opt; do
  startup_log "Processing command line opt: ${opt}"
  case $opt in
  e)
    export SERVER_HELP_EMAIL=$OPTARG
    startup_log "Set SERVER_HELP_EMAIL: ${SERVER_HELP_EMAIL}"
    ;;
  s)
    export FOLLOW_SYMLINKS="Yes"
    startup_log "Set FOLLOW_SYMLINKS: ${FOLLOW_SYMLINKS}"
    ;;
  n)
    export NCWMS_BASE=$OPTARG
    startup_log "Set NCWMS_BASE: ${NCWMS_BASE}"
    ;;
  k)
    export AWS_SECRET_ACCESS_KEY="${OPTARG}"
    startup_log "Set AWS_SECRET_ACCESS_KEY"
    ;;
  i)
    export AWS_ACCESS_KEY_ID="${OPTARG}"
    startup_log "Set AWS_ACCESS_KEY_ID"
    ;;
  r)
    export AWS_DEFAULT_REGION="${OPTARG}"
    startup_log "Set AWS_DEFAULT_REGION"
    ;;

  \?)
    echo  "Invalid option: -$OPTARG" >&2
    echo "options: [-e xxx] [-n yyy] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]" >&2
    echo " -e xxx where xxx is the email address of the admin contact for the server." >&2
    echo " -s When present causes the BES to follow symbolic links." >&2
    echo " -n yyy where yyy is the protocol, server and port part " >&2
    echo "    of the ncWMS service (for example http://foo.com:8090)." >&2
    echo " -d Enables debugging output for this script." >&2
    echo " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID." >&2
    echo " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY." >&2
    echo " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION." >&2
    echo "EXITING NOW" >&2
    exit 2
    ;;
  esac
done
#
# END Command Line Processing
################################################################################

if test "${debug}" = "true"; then
  startup_log "CATALINA_HOME: ${CATALINA_HOME}"
  startup_log "   " $(ls -l "${CATALINA_HOME}")
  startup_log "CATALINA_HOME/bin: ${CATALINA_HOME}/bin"
  startup_log "   " $(ls -l "${CATALINA_HOME}/bin")
fi

################################################################################
#
#  Configuring NcWMS
#
VIEWERS_XML="${OLFS_CONF_DIR}/viewers.xml"
if test "${debug}" = "true"; then
  startup_log "NCWMS: Using NCWMS_BASE: ${NCWMS_BASE}"
  startup_log "NCWMS: Setting ncWMS access URLs in viewers.xml (if needed)."
  startup_log $(ls -l "${VIEWERS_XML}")
fi

if test -f "${VIEWERS_XML}"; then
  sed -i "s+@NCWMS_BASE@+${NCWMS_BASE}+g" "${VIEWERS_XML}"
fi

if test "${debug}" = "true"; then
  startup_log "${VIEWERS_XML}: "
  startup_log $(cat "${VIEWERS_XML}" | awk '{print "#    "$0;}')
fi
################################################################################

################################################################################
#
# Configure OLFS debug logging if debug is enabled.
if test "${debug}" = "true"; then
  startup_log "Configuring OLFS to debug logging..."
  logback_xml="${OLFS_CONF_DIR}/logback.xml"
  ngap_logback_xml="${OLFS_CONF_DIR}/logback-ngap.xml"
  cp "${ngap_logback_xml}" "${logback_xml}"
  startup_log "Enabled Logback (slf4j) debug logging for NGAP."
  startup_log $( cat "${logback_xml}" )
fi
################################################################################

################################################################################
#
# modify bes.conf based on environment variables before startup.
#
if test "${SERVER_HELP_EMAIL}" != "not_set"; then
  startup_log "Setting Admin Contact To: $SERVER_HELP_EMAIL"
  sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
fi
if test "${FOLLOW_SYMLINKS}" != "not_set"; then
  startup_log "Setting BES FollowSymLinks to YES."
  sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
fi
################################################################################

#-------------------------------------------------------------------------------
# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
bes_uid=$(id -u bes)
bes_gid=$(id -g bes)
startup_log "Launching besd [uid: ${bes_uid} gid: ${bes_gid}]"
/usr/bin/besctl start 2>&1 > ./besctl.log # dropped debug control -d "/dev/null,timing"  - ndp 10/12/2023
status=$?
startup_log $(cat ./besctl.log)
if test $status -ne 0; then
  error_log "ERROR: Failed to start BES: $status"
  #exit $status
fi
besd_pid=$(ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' -)
startup_log "The besd is UP! [pid: ${besd_pid}]"

#-------------------------------------------------------------------------------
# Start Tomcat process
#
startup_log "Starting tomcat/olfs..."

# mv ${OLFS_CONF_DIR}/logback.xml ${OLFS_CONF_DIR}/logback.xml.OFF
#systemctl start tomcat

${CATALINA_HOME}/bin/startup.sh 2>&1 >/var/log/tomcat/console.log &
status=$?
tomcat_pid=$!
if test $status -ne 0; then
  error_log "ERROR: Failed to start Tomcat: $status"
  #exit $status
fi
# When we launch tomcat the initial pid gets "retired" because it spawns a
# secondary processes.
initial_pid="${tomcat_pid}"
startup_log "Tomcat started, initial pid: ${initial_pid}"
while test $initial_pid -eq $tomcat_pid; do
  sleep 1
  tomcat_ps=$(ps aux | grep tomcat | grep -v grep)
  startup_log "tomcat_ps: ${tomcat_ps}"
  tomcat_pid=$(echo ${tomcat_ps} | awk '{print $2}')
  startup_log "tomcat_pid: ${tomcat_pid}"
done
# New pid and we should be good to go.
startup_log "Tomcat is UP! pid: ${tomcat_pid}"

# TEMPORARY ###################################################################
/cleanup_files.sh >&2 &
# TEMPORARY ###################################################################

#-------------------------------------------------------------------------------
# Get the bes log, make it json, and send it to stdout
#
tail -f "${BES_LOG_FILE}" | beslog2json.py --prefix "${LOG_KEY_PREFIX}" &

start_time=
now=
suptime=
start_time=$(date  "+%s")
#-------------------------------------------------------------------------------
startup_log "Hyrax Has Arrived...(time: $start_time)"
#-------------------------------------------------------------------------------
while /bin/true; do
  sleep ${SLEEP_INTERVAL}

  # Compute service_uptime in hours
  now=$(date  "+%s")
  suptime=$(echo "scale=4; ($now - $start_time)/60/60" | bc)

  if test "$debug" = "true"; then
    heartbeat_log "Checking Hyrax Operational State. service_uptime: ${suptime} hours";
  fi

  besd_ps=$(ps -f $besd_pid)
  BESD_STATUS=$?

  if test "$debug" = "true"; then
    heartbeat_log "besd_ps: ${besd_ps}";
  fi
  if test "$debug" = "true"; then
    heartbeat_log "BESD_STATUS: ${BESD_STATUS}";
  fi

  if test $BESD_STATUS -ne 0; then
    error_log "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid"
    error_log "The BES daemon appears to have died! Exiting. (service_uptime: ${suptime} hours)"
    #exit $BESD_STATUS
  fi

  tomcat_ps=$(ps -f "${tomcat_pid}")
  TOMCAT_STATUS=$?
  if test "$debug" = "true"; then heartbeat_log "TOMCAT_STATUS: ${TOMCAT_STATUS}"; fi
  if test $TOMCAT_STATUS -ne 0; then
    error_log "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
    error_log "Tomcat appears to have died! Exiting.  (service_uptime: ${suptime} hours)"
    # write_tomcat_logs 100 5 # [number of log lines to grab from each file] [time to sleep after sending]
    #exit $TOMCAT_STATUS
  fi

done
#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------
