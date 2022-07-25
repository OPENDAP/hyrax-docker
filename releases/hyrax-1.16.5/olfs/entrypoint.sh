#!/bin/bash
# This is the entrypoint.sh file for the olfs container.
#
#
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## OLFS ##################################";   >&2
echo "Greetings, I am "`whoami`".";   >&2
set -e
#set -x

if [ $NCWMS_BASE ] && [ -n $NCWMS_BASE ] ; then    
    echo "Found exisiting NCWMS_BASE: $NCWMS_BASE"  
else 
    NCWMS_BASE="https://localhost:8080"
     echo "Assigning default NCWMS_BASE: $NCWMS_BASE"  
fi
debug=false;

while getopts "n:d" opt; do
  case $opt in
    n)
      echo "Setting ncWMS base URL to: $OPTARG" >&2
      NCWMS_BASE=$OPTARG
      ;;
    d)
      debug=true;
      echo "Debug is enabled" >&2;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-n ncwms_base_url] [-d] " >&2
      echo " -n xxx where xxx is the protocol, server and port part " >&2
      echo "    of the ncWMS service (for example http://foo.com:8090/)." >&2
      echo " -d Enables debugging output for this script." >&2
      echo "EXITING NOW" >&2
      exit 2;
      ;;
  esac
done

if [ $debug = true ];then
    echo "CATALINA_HOME: ${CATALINA_HOME}"; >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
    echo "NCWMS_BASE: ${NCWMS_BASE}" >&2
    echo "Setting ncWMS access URLs in viewers.xml (if needed)." >&2
fi

sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml;
if [ $debug = true ];then
    echo "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml" >&2
    cat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml >&2
fi

# $CATALINA_HOME/bin/start-tomcat.sh
$CATALINA_HOME/bin/startup.sh
status=$?
if [ $status != "0" ];then 
    echo "Failed to launch the Tomcat process. status: ${status} EXITING!"; >&2
    exit 2; 
fi

echo "Launched Tomcat." >&2

tomcat_key="/usr/local/tomcat/bin/tomcat-juli.jar";

tomcat_info=`ps -f | grep ${tomcat_key} - `;
status=$?
echo "tomcat_info: $tomcat_info status: $status" >&2

if [ $status != "0" ];then 
    echo "Unable to detect Tomcat process. status: ${status} EXITING!"; >&2
    exit 2; 
fi

tomcat_pid=`echo $tomcat_info | awk '{print $2}' -`

echo "Tomcat Has Arrived. (pid: $tomcat_pid)" >&2


while /bin/true; do
    sleep 60
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

