#!/bin/bash
# This is the entrypoint.sh file for the ncWMS container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## ncWMS ##################################";   >&2
echo "Greetings, I am "`whoami`".";   >&2
echo "CATALINA_HOME: ${CATALINA_HOME}"; >&2
set -e
#set -x

debug=false;

while getopts "d" opt; do
  case $opt in
    d)
      debug=true;
      echo "Debug is enabled" >&2;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-d] " >&2
      echo " -d Enables debugging output for this script." >&2
      echo "EXITING NOW" >&2
      exit 2;
      ;;
  esac
done
if [ $debug = true ];then
    echo "CATALINA_HOME: ${CATALINA_HOME}";  >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
fi


trap "echo TRAPed signal" HUP INT QUIT KILL TERM

# startup.sh -security
startup.sh -security # Without --security makes ncWMS work because the CORS filter get's tangled up with the security manager.

tomcat_info=`ps -f | grep ${tomcat_key} - `;
status=$?
echo "tomcat_info: $tomcat_info status: $status" >&2

if [ $status != "0" ];then 
    echo "Unable to detect Tomcat process. status: ${status} EXITING!"; >&2
    exit 2; 
fi

tomcat_pid=`echo $tomcat_info | awk '{print $2}' -`

echo "Tomcat Has Arrived. (pid: $tomcat_pid)" >&2

# tail -f /usr/local/tomcat/logs/catalina.out
# never exit
while true; do 
    sleep 60; 
    tomcat_ps=`ps -f $tomcat_pid`;
    TOMCAT_STATUS=$?
    if [ $TOMCAT_STATUS -ne 0 ]; then
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
        echo "Tomcat appears to have died! Exiting." >&2
        echo "Tomcat Console Log [BEGIN]" >&2
        cat /usr/local/tomcat/logs/catalina.out >&2
        echo "Tomcat Console Log [END]" >&2
        exit -2;
    fi
    if [ $debug = true ];then 
        echo "-------------------------------------------------------------------"
        date
        echo "TOMCAT_STATUS: $TOMCAT_STATUS  tomcat_pid:$tomcat_pid"
    fi
done


