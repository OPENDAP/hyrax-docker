#!/bin/bash
#set -exv
set -e
echo "entrypoint.sh commmandline: $@"
echo "user: "`whoami`

echo "CATALINA_HOME: "$CATALINA_HOME
ls -l "$CATALINA_HOME"
ls -l "$CATALINA_HOME/logs"

set -e
set -x

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

# startup.sh -security
startup.sh # Without --security makes ncWMS because the CORS filter get's tangled up with the security manager.

# tail -f /usr/local/tomcat/logs/catalina.out
# never exit
while true; do sleep 60; echo -n "."; done


