#!/bin/bash
# This is the entrypoint.sh file for the besd container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "Command line: \"$@\""
echo "############################## BESD ##################################";   >&2
echo "Greetings, I am "`whoami`".";   >&2


echo "PythonVersion: "$(python3 --version)

if [ "$SERVER_HELP_EMAIL" ] && [ -n "$SERVER_HELP_EMAIL" ] ; then
    echo "Found exisiting SERVER_HELP_EMAIL: $SERVER_HELP_EMAIL"  
else 
    SERVER_HELP_EMAIL="not_set"
    echo "SERVER_HELP_EMAIL is $SERVER_HELP_EMAIL"
fi
if [ "$FOLLOW_SYMLINKS" ] && [ -n "$FOLLOW_SYMLINKS" ] ; then
    echo "Found exisiting FOLLOW_SYMLINKS: $FOLLOW_SYMLINKS"  
else 
    FOLLOW_SYMLINKS="not_set";
    echo "FOLLOW_SYMLINKS is $FOLLOW_SYMLINKS"
fi

#AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-<not set>}"
#echo "AWS_SECRET_ACCESS_KEY is ${AWS_SECRET_ACCESS_KEY}"
#
#AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-<not set>}"
#echo "AWS_ACCESS_KEY_ID is ${AWS_ACCESS_KEY_ID}"
#
#AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-<not set>}"
#echo "AWS_DEFAULT_REGION is ${AWS_DEFAULT_REGION}"


debug=false;

while getopts "e:sdi:k:r:" opt; do
  case $opt in
    e)
      #echo "Setting server admin contact email to: $OPTARG" >&2
      SERVER_HELP_EMAIL=$OPTARG
      ;;
    s)
      #echo "Setting FollowSymLinks to: Yes" >&2
      FOLLOW_SYMLINKS="Yes"
      ;;
    d)
      debug=true;
      echo "Debug is enabled" >&2;
      ;;
    k)
      AWS_SECRET_ACCESS_KEY="${OPTARG}"
      echo "Found command line value for AWS_SECRET_ACCESS_KEY: ${AWS_SECRET_ACCESS_KEY}" >&2;
      ;;
    i)
      AWS_ACCESS_KEY_ID="${OPTARG}"
      echo "Found command line value for AWS_ACCESS_KEY_ID: ${AWS_ACCESS_KEY_ID}" >&2;
      ;;
    r)
      AWS_DEFAULT_REGION="${OPTARG}"
      echo "Found command line value for AWS_DEFAULT_REGION: ${AWS_DEFAULT_REGION}" >&2;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-e xxx] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]" >&2
      echo " -e xxx where xxx is the email address of the admin contact for the server." >&2
      echo " -s When present causes the BES to follow symbolic links." >&2
      echo " -d Enables debugging output for this script." >&2
      echo " -i xxx Where xxx is an AWS CLI AWS_ACCESS_KEY_ID." >&2
      echo " -k xxx Where xxx is an AWS CLI AWS_SECRET_ACCESS_KEY." >&2
      echo " -r xxx Where xxx is an AWS CLI AWS_DEFAULT_REGION." >&2
      exit 2;
      ;;
  esac
done

################################################################################
echo "Checking AWS CLI: " >&2
set +e
aws_bin="$(which aws 2>&1)"
ab_status=$?
set -e
if test $ab_status -ne 0; then
    echo "WARNING: It appears that the AWS CLI is not installed. Not found on '$PATH' ('which' status: $ab_status, msg: $aws_bin)" >&2
else
    acl="$(aws configure list 2>&1)"
    acl_status=$?
    echo "$acl" >&2
    if test $acl_status -ne 0; then
      echo "WARNING: Problem with AWS CLI! ('aws' status: $acl_status msg: $acl)"  >&2
    fi
fi
# echo "$@"


# modify bes.conf based on environment variables before startup. These are set in 
# the Docker file to "not_set" and are overriden by the commandline here
#
if [ $SERVER_HELP_EMAIL != "not_set" ]; then
    echo "Setting Admin Contact To: $SERVER_HELP_EMAIL" >&2
    sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
fi
if [ $FOLLOW_SYMLINKS != "not_set" ]; then
    echo "Setting BES FollowSymLinks to YES." >&2
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
fi


# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
/usr/bin/besctl start; 
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start BES: $status" >&2
    exit $status
fi

besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `;
echo "The besdaemon is UP! pid: $besd_pid"  >&2

echo "BES Has Arrived..."  >&2

while /bin/true; do
    sleep 60
    besd_ps="$(ps -f "$besd_pid")";
    BESD_STATUS=$?
    if [ $BESD_STATUS -ne 0 ]; then
        echo "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid" >&2
        echo "The BES daemon appears to have died! Exiting."  >&2
        exit 1;
    else
        echo "Found besd: $besd_ps"
    fi
    if [ $debug = true ];then 
        echo "-------------------------------------------------------------------" >&2
        date >&2
        echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid" >&2
    fi
done 
