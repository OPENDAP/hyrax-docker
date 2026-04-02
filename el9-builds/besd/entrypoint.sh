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
export BANNER="################################# BES #############################################"
export HR0="###################################################################################"
export HR1="-----------------------------------------------------------------------------------"
export HR2="-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --"
export prolog="entrypoint.sh -"
function loggy(){
    echo  "$@" | awk -v prolog="$prolog" '{ print "# " prolog " " $0;}'  >&2
}

SECONDS=0
loggy "$HR0"
loggy "$BANNER"
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
loggy "SLEEP_INTERVAL: $SLEEP_INTERVAL seconds."

# As set in Dockerfile
export BES_USER=${BES_USER:-"bes_user"}

while getopts "e:sd" opt; do
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
    \?)
      loggy "Invalid option: -$OPTARG"
      loggy "options: [-e xxx] [-s] [-d] [-i xxx] [-k xxx] [-r xxx]"
      loggy " -e xxx where xxx is the email address of the admin contact for the server."
      loggy " -s When present causes the BES to follow symbolic links."
      loggy " -d Enables debugging output for this script."
      exit 2;
      ;;
  esac
done

################################################################################
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
besd_pid="$(echo "$process_list" | grep "$BESD" | grep -v grep | awk '{print $2;}' -)"
#besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `
besd_pid=
if test -z "$besd_pid"
then
    loggy "ERROR!  Failed to acquire a PID for the besdaemon process. The BES may not have started. (Elapsed $SECONDS seconds) EXITING NOW!"
    exit 1
fi
loggy "The besdaemon is UP! pid: $besd_pid"

start_time=
start_time="$(date  "+%s")"
loggy "The BES Has Arrived...(time: $start_time, SLEEP_INTERVAL: $SLEEP_INTERVAL)"
loggy "$HR0"

while /bin/true; do
    sleep $SLEEP_INTERVAL
    besd_ps="$(ps -f "$besd_pid")";
    BESD_STATUS=$?
    if test $BESD_STATUS -ne 0
    then
        loggy "BESD_STATUS: $BESD_STATUS bes_pid: $bes_pid"
        loggy "The BES daemon appears to have died! Exiting."
        exit 1;
    fi

    if test "$debug" = "true";
    then
        loggy "$(date) BESD_STATUS: $BESD_STATUS  besd_pid: $besd_pid"
    fi
done 
