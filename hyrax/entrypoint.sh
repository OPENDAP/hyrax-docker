#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.
#set -exv
#set -e
echo "$@"

echo "My username is: "`whoami`;  

# Start the BES daemon process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
/usr/bin/besctl start; 
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start BES: $status"
    exit $status
fi
besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `;
echo "The BES is UP! pid: $besd_pid";


# Start Tomcat process
/usr/libexec/tomcat/server start > /var/log/tomcat/console.log 2>&1 &
status=$?
tomcat_pid=$!
if [ $status -ne 0 ]; then
    echo "Failed to start Tomcat: $status"
    exit $status
fi
#echo "-------------------------------------------------------------------"
#ps aux;
#echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Tomcat is UP! pid: $tomcat_pid";
echo "Hyrax Has Arrived...";

while /bin/true; do
    sleep 60
    echo "-------------------------------------------------------------------"
    #ps aux;
    #echo "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
    besd_ps=`ps -f $besd_pid`;
    BESD_STATUS=$?
    echo "BESD_STATUS: $BESD_STATUS  besd_pid:$besd_pid"
    
    tomcat_ps=`ps -f $tomcat_pid`;
    #ps aux | grep tomcat | grep -v grep;
    TOMCAT_STATUS=$?
    echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"

    if [ $BESD_STATUS -ne 0 ]; then
        echo "BESD_STATUS: $BESD_STATUS bes_pid:$bes_pid"
        echo "The BES daemon appears to have died! Exiting."
        exit -1;
    fi
    if [ $TOMCAT_STATUS -ne 0 ]; then
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat_pid:$tomcat_pid"
        echo "Tomcat appears to have died! Exiting."
        echo "Tomcat Console Log [BEGIN]"
        cat /usr/share/tomcat/logs/console.log;
        echo "Tomcat Console Log [END]"
        exit -2;
    fi
done
 
