#!/bin/bash
# This is the entrypoint.sh file for the besd container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
export BANNER="################################## BES ############################################"
export HR0="###################################################################################"
export HR1="-----------------------------------------------------------------------------------"
export HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
export prolog="entrypoint.sh"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "# "prolog" - " $0;}' >&2
}

#loggy "Command line: \"$@\""
loggy "$BANNER";  
loggy "Greetings, I am $(whoami).";


loggy "PythonVersion: $(python3 --version)"

if [ -n "$SERVER_HELP_EMAIL" ] 
then
    loggy "Found exisiting SERVER_HELP_EMAIL: $SERVER_HELP_EMAIL"
else 
    SERVER_HELP_EMAIL="not_set"
    loggy "SERVER_HELP_EMAIL is $SERVER_HELP_EMAIL"
fi
if [ -n "$FOLLOW_SYMLINKS" ] ; then
    loggy "Found exisiting FOLLOW_SYMLINKS: $FOLLOW_SYMLINKS"
else 
    FOLLOW_SYMLINKS="not_set";
    loggy "FOLLOW_SYMLINKS is $FOLLOW_SYMLINKS"
fi

#AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-<not set>}"
#loggy "AWS_SECRET_ACCESS_KEY is ${AWS_SECRET_ACCESS_KEY}"
#
#AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-<not set>}"
#loggy "AWS_ACCESS_KEY_ID is ${AWS_ACCESS_KEY_ID}"
#
#AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-<not set>}"
#loggy "AWS_DEFAULT_REGION is ${AWS_DEFAULT_REGION}"


debug=false;

while getopts "e:sdi:k:r:" opt; do
  case $opt in
    e)
      #loggy "Setting server admin contact email to: $OPTARG"
      SERVER_HELP_EMAIL=$OPTARG
      ;;
    s)
      #loggy "Setting FollowSymLinks to: Yes"
      FOLLOW_SYMLINKS="Yes"
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

#aws configure list
#status=$?
#if [ $status -ne 0 ]; then
#    loggy "Problem with AWS CLI!"
#fi

set -e
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

#-------------------------------------------------------------------------------
# We use 'echo' in the following because downstream code is expecting this
# output to be a key value pair, so none of that loggy() stuff
bes_username=$BES_USER
bes_uid=$(id -u "$bes_username")
bes_gid=$(id -g "$bes_username")
echo "bes_uid: $bes_uid"
echo "bes_gid: $bes_gid"

# Where is my precious? Is the precious on the path?
BESD="$(which besdaemon)"
loggy "The besdaemon is here: $BESD"

# Start the BES daemon process
loggy "Calling 'besctl start'"
/usr/bin/besctl start > ./besctl.log 2>&1
status=$?
loggy "$(cat ./besctl.log)"
if [ $status -ne 0 ]; then
    loggy "ERROR: Failed to start BES: $status"
    exit $status
fi

process_list="$(ps aux)"
loggy "process_list:"
loggy "$process_list"
besd_pid="$(loggy "$process_list" | grep "$BESD" | grep -v grep | awk '{print $2;}' -)"
if test -z "$besd_pid"
then
    loggy "ERROR! Failed to acquire a PID for the besdaemon process. The BES did not start. (Elapsed $SECONDS seconds) EXITING NOW!"
    exit 1
fi
loggy "The besdaemon is UP! pid: $besd_pid"

loggy "BES Has Arrived..." 

while /bin/true; do
    sleep 60
    besd_ps="$(ps -f "$besd_pid")"
    BESD_STATUS=$?
    if [ $BESD_STATUS -ne 0 ]; then
        loggy "BESD_STATUS: $BESD_STATUS bes_pid: $besd_pid"
        loggy "The BES daemon appears to have died! Exiting." 
        exit $BESD_STATUS;
    fi
    if [ $debug = true ];then 
        loggy "-------------------------------------------------------------------"
        date
        loggy "BESD_STATUS: $BESD_STATUS  besd_pid: $besd_pid"
    fi
done 
