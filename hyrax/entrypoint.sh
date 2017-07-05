#!/bin/bash
# This is the entrypoint.sh file for the single container Hyrax.
#set -exv
set -e
echo "$@"

echo "My username is: "`whoami`;  ls -l /var/log/bes


# ls -la /etc/init.d/*
# more /etc/init.d/README
# ls -la $CATALINA_HOME  $CATALINA_HOME/bin $CATALINA_HOME/webapps


# Start the first process
# /usr/bin/besdaemon -i /usr -c /etc/bes/bes.conf -r /var/run/bes.pid
/usr/bin/besctl start; 
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start BES: $status"
    exit $status
else 
    echo "The BES is UP!"
fi
besd_pid=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `;
echo "besd_pid:   $besd_pid";


# Start Tomcat 
/usr/libexec/tomcat/server start > /usr/share/tomcat/logs/console.log 2>&1 &
status=$?
tomcat_pid=$!
if [ $status -ne 0 ]; then
    echo "Failed to start Tomcat: $status"
    exit $status
else
    echo "Tomcat is UP!"
fi
echo "tomcat_pid: $tomcat_pid";
echo "Hyrax Has Been Started.";


#tomcat_pid=`ps aux`; #| grep /usr/libexec/tomcat/server`; #| awk '{print $2;}' - `;


while /bin/true; do
    sleep 60
    echo "------------------------------------------------------------------"
    # ps aux | grep besdaemon | grep -v grep;
    besd=`ps aux | grep /usr/bin/besdaemon | grep -v grep | awk '{print $2;}' - `;
    BESD_STATUS=$?
    echo "BESD_STATUS: $BESD_STATUS besd:$besd besd_pid:$besd_pid"
    tomcat=`ps aux | grep /usr/share/tomcat/bin/bootstrap.jar | grep -v grep | awk '{print $2;}' - `;
    TOMCAT_STATUS=$?
    echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat:$tomcat tomcat_pid:$tomcat_pid"

    if [    $BESD_STATUS -ne 0 
         -o $TOMCAT_STATUS -ne 0 
         -o $besd -ne $besd_pid 
         -o $tomcat -ne $tomcat_pid
         ]; then
        echo "BESD_STATUS: $BESD_STATUS besd:$besd bes_pid:$bes_pid"
        echo "TOMCAT_STATUS: $TOMCAT_STATUS tomcat:$tomcat tomcat_pid:$tomcat_pid"
        echo "Somebody died! Exiting..."
        exit -1
    fi
done
 
