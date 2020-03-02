#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.

# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.

#echo "entrypoint.sh  command line: \"$@\""
echo "############################## HYRAX ##################################";   >&2
echo "Greetings, I am "`whoami`".";   >&2
set -e
#set -x

# Hyrax-in-the-cloud configuration
# Only create the /etc/bes/site.conf file if all the necessary environment variables are defined
if [ $S3_DISTRIBUTION_ENDPOINT ] &&  [ $S3_REFRESH_MARGIN ] && [ $S3_AWS_REGION ] && [ $S3_BASE_URL ]; then
    echo "NGAP.S3.distribution.endpoint.url=$S3_DISTRIBUTION_ENDPOINT" >> /etc/bes/site.conf
    echo "NGAP.S3.refresh.margin=$S3_REFRESH_MARGIN" >> /etc/bes/site.conf
    echo "NGAP.S3.region=$S3_AWS_REGION" >> /etc/bes/site.conf
    echo "NGAP.S3.url.base=$S3_BASE_URL" >> /etc/bes/site.conf
fi

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

if [ $NCWMS_BASE ] && [ -n $NCWMS_BASE ] ; then    
    echo "Found exisiting NCWMS_BASE: $NCWMS_BASE"  
else 
    NCWMS_BASE="https://localhost:8080"
     echo "Assigning default NCWMS_BASE: $NCWMS_BASE"  
fi
debug=false;

while getopts "de:sn:" opt; do
  echo "Processing command line opt: ${opt}" >&2
  case $opt in
    e)
      echo "Setting server admin contact email to: $OPTARG" >&2
      SERVER_HELP_EMAIL=$OPTARG
      ;;
    s)
      echo "Setting FollowSymLinks to: Yes" >&2
      FOLLOW_SYMLINKS="Yes"
      ;;
    n)
      echo "Setting ncWMS public facing service base to : $OPTARG" >&2
      NCWMS_BASE=$OPTARG
      ;;
    d)
      debug=true;
      echo "Debug is enabled" >&2;
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "options: [-e xxx] [-s] [-n yyy] [-d] "  >&2
      echo " -e xxx where xxx is the email address of the admin contact for the server."
      echo " -s When present causes the BES to follow symbolic links."
      echo " -n yyy where yyy is the protocol, server and port part "  >&2
      echo "    of the ncWMS service (for example http://foo.com:8090)."  >&2
      echo " -d Enables debugging output for this script."  >&2
      echo "EXITING NOW"  >&2
      exit 2;
      ;;
  esac
done

if [ $debug = true ];then
    echo "CATALINA_HOME: ${CATALINA_HOME}";  >&2
    ls -l "$CATALINA_HOME" "$CATALINA_HOME/bin"  >&2
fi

if [ $debug = true ];then
    echo "NCWMS_BASE: ${NCWMS_BASE}"  >&2
    echo "Setting ncWMS access URLs in viewers.xml (if needed).";  >&2
fi

sed -i "s+@NCWMS_BASE@+$NCWMS_BASE+g" ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml;
if [ $debug = true ];then
    echo "${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml";  >&2
    cat ${CATALINA_HOME}/webapps/opendap/WEB-INF/conf/viewers.xml; >&2
fi

# modify bes.conf based on environment variables before startup.
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
    echo "Failed to start BES: $status" >&2
    exit $status
fi
besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `;
echo "The BES is UP! pid: $besd_pid"; >&2


# Start Tomcat process
/usr/libexec/tomcat/server start > /var/log/tomcat/console.log 2>&1 &
status=$?
tomcat_pid=$!
if [ $status -ne 0 ]; then
    echo "Failed to start Tomcat: $status" >&2
    exit $status
fi
echo "Tomcat is UP! pid: $tomcat_pid"; >&2

echo "Hyrax Has Arrived..."; >&2

while /bin/true; do
    sleep 60
    besd_ps=`ps -f $besd_pid`;
    BESD_STATUS=$?
    
    tomcat_ps=`ps -f $tomcat_pid`;
    TOMCAT_STATUS=$?

    if [ $BESD_STATUS -ne 0 ]; then
        echo "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid" >&2
        echo "The BES daemon appears to have died! Exiting." >&2
        exit -1;
    fi
    if [ $TOMCAT_STATUS -ne 0 ]; then
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
        echo "Tomcat appears to have died! Exiting." >&2
        echo "Tomcat Console Log [BEGIN]" >&2
        cat /usr/share/tomcat/logs/console.log >&2
        echo "Tomcat Console Log [END]" >&2
        exit -2;
    fi
    
    if [ $debug = true ];then
        echo "-------------------------------------------------------------------"  >&2
        date >&2
        echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid" >&2
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid" >&2
    fi

    
done
 
