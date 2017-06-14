#!bin/bash


# Run the besd container (works)
docker run -itd -p 10022:10022 --name=besd bes-3.18.0-static

# Run the OLFS and "link" it to the besd container
docker run -itd -p 8080:8080 -v /tmp:/usr/local/tomcat/webapps/opendap/WEB-INF/conf/logs --link besd --name=olfs olfs-1.16.3 

