#!/bin/bash
# This is the entrypoint.sh file for the besd container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
#
export debug=false
export HR0="###################################################################################"
export HR1="-----------------------------------------------------------------------------------"
export HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
export prolog="entrypoint.sh -"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "#" prolog " " $0;}'  >&2
}

loggy "############################## BESD ##################################"
loggy "Greetings, I am $(whoami) (uid: $UID)"
loggy "PythonVersion: $(python3 --version)"

if [ "$SERVER_HELP_EMAIL" ] && [ -n "$SERVER_HELP_EMAIL" ] ; then
    loggy "Found existing SERVER_HELP_EMAIL: $SERVER_HELP_EMAIL"
else 
    SERVER_HELP_EMAIL="not_set"
    loggy "SERVER_HELP_EMAIL is $SERVER_HELP_EMAIL"
fi
if [ "$FOLLOW_SYMLINKS" ] && [ -n "$FOLLOW_SYMLINKS" ] ; then
    loggy "Found existing FOLLOW_SYMLINKS: $FOLLOW_SYMLINKS"
else 
    FOLLOW_SYMLINKS="not_set";
    loggy "FOLLOW_SYMLINKS is $FOLLOW_SYMLINKS"
fi

export SLEEP_INTERVAL="${SLEEP_INTERVAL:-60}"
startup_log "SLEEP_INTERVAL: $SLEEP_INTERVAL seconds."

#AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-<not set>}"
#loggy "AWS_SECRET_ACCESS_KEY is ${AWS_SECRET_ACCESS_KEY}"
#
#AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-<not set>}"
#loggy "AWS_ACCESS_KEY_ID is ${AWS_ACCESS_KEY_ID}"
#
#AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-<not set>}"
#loggy "AWS_DEFAULT_REGION is ${AWS_DEFAULT_REGION}"


while getopts "e:sdi:k:r:" opt; do
  case $opt in
    e)
      SERVER_HELP_EMAIL=$OPTARG
      loggy "SERVER_HELP_EMAIL: $SERVER_HELP_EMAIL";
      ;;
    s)
      FOLLOW_SYMLINKS="Yes"
      loggy "FOLLOW_SYMLINKS: $FOLLOW_SYMLINKS";
      ;;
    d)
      debug=true;
      loggy "Debug is enabled";
      ;;
    k)
      AWS_SECRET_ACCESS_KEY="${OPTARG}"
      loggy "Found command line value for AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}";
      ;;
    i)
      AWS_ACCESS_KEY_ID="${OPTARG}"
      loggy "Found command line value for AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}";
      ;;
    r)
      AWS_DEFAULT_REGION="${OPTARG}"
      loggy "Found command line value for AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}";
      ;;
    \?)
      loggy "Invalid option: -$OPTARG"
      loggy "options: [-e xxx] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]"
      loggy " -e xxx where xxx is the email address of the admin contact for the server."
      loggy " -s When present causes the BES to follow symbolic links."
      loggy " -d Enables debugging output for this script."
      loggy " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID."
      loggy " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY."
      loggy " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION."
      exit 2;
      ;;
  esac
done

################################################################################
loggy "Checking AWS CLI: "
set +e
aws_bin="$(which aws 2>&1)"
ab_status=$?
set -e
if test $ab_status -ne 0; then
    loggy "WARNING: It appears that the AWS CLI is not installed. Not found on '$PATH' ('which' status: $ab_status, msg: $aws_bin)"
else
    acl="$(aws configure list 2>&1)"
    acl_status=$?
    loggy "$acl"
    if test $acl_status -ne 0; then
      loggy "WARNING: Problem with AWS CLI! ('aws' status: $acl_status msg: $acl)"
    fi
fi
# loggy "$@"


# modify bes.conf based on environment variables before startup. These are set in 
# the Docker file to "not_set" and are overriden by the commandline here
#
if [ "$SERVER_HELP_EMAIL" != "not_set" ]; then
    loggy "Setting Admin Contact To: $SERVER_HELP_EMAIL"
    sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
fi
if [ "$FOLLOW_SYMLINKS" != "not_set" ]; then
    loggy "Setting BES FollowSymLinks to YES."
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
fi


# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
/usr/bin/besctl start; 
status=$?
if [ $status -ne 0 ]; then
    loggy "ERROR: Failed to start BES: $status"
    exit $status
fi

besd_pid="$(ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - )"
loggy "The besdaemon is UP! pid: $besd_pid"
start_time=
start_time="$(date  "+%s")"
startup_log "BES Has Arrived...(time: $start_time, SLEEP_INTERVAL: $SLEEP_INTERVAL)"

while /bin/true; do
    sleep $SLEEP_INTERVAL
    besd_ps="$(ps -f "$besd_pid")";
    BESD_STATUS=$?
    if [ $BESD_STATUS -ne 0 ]; then
        loggy "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid"
        loggy "The BES daemon appears to have died! Exiting."
        exit 1;
    else
        loggy "Found besd: $besd_ps"
    fi
    if [ $debug = true ];then 
        loggy "$HR1"
        loggy "$(date)"
        loggy "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid"
    fi
done 
