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

if [ $SERVER_HELP_EMAIL ] && [ -n $SERVER_HELP_EMAIL ] ; then    
    echo "Found exisiting SERVER_HELP_EMAIL: $SERVER_HELP_EMAIL"  
else 
    SERVER_HELP_EMAIL="not_set"
    echo "SERVER_HELP_EMAIL is $SERVER_HELP_EMAIL"
fi
if [ $FOLLOW_SYMLINKS ] && [ -n $FOLLOW_SYMLINKS ] ; then    
    echo "Found exisiting FOLLOW_SYMLINKS: $FOLLOW_SYMLINKS"  
else 
    FOLLOW_SYMLINKS="not_set";
    echo "FOLLOW_SYMLINKS is $FOLLOW_SYMLINKS"
fi

debug=false;

while getopts "e:sd" opt; do
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
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-e email_address] [-s] [-d] "
      echo " -e xxx where xxx is the email address of the admin contact for the server."
      echo " -s When present causes the BES to follow symbolic links."
      echo " -d Enables debugging output for this script."
      exit 2;
      ;;
  esac
done
set -e
# echo "$@"


# modify bes.conf based on environment variables before startup. These are set in 
# the Docker file to "not_set" and are overriden by the commandline here
#
if [ $SERVER_HELP_EMAIL != "not_set" ]; then
    echo "Setting Admin Contact To: $SERVER_HELP_EMAIL"
    sed -i "s/admin.email.address@your.domain.name/$SERVER_HELP_EMAIL/" /etc/bes/bes.conf
fi
if [ $FOLLOW_SYMLINKS != "not_set" ]; then
    echo "Setting BES FollowSymLinks to YES."
    sed -i "s/^BES.Catalog.catalog.FollowSymLinks=No/BES.Catalog.catalog.FollowSymLinks=Yes/" /etc/bes/bes.conf
fi


# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
/usr/bin/besctl start; 
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start BES: $status"
    exit $status
fi

besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `;
echo "The besdaemon is UP! pid: $besd_pid";

echo "BES Has Arrived...";

while /bin/true; do
    sleep 60
    besd_ps=`ps -f $besd_pid`;
    BESD_STATUS=$?
    if [ $BESD_STATUS -ne 0 ]; then
        echo "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid"
        echo "The BES daemon appears to have died! Exiting."
        exit -1;
    fi
    if [ $debug = true ];then 
        echo "-------------------------------------------------------------------"
        date
        echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid"
    fi
done 
