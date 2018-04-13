# Hyrax docker

Current Version:
 
 **Hyrax-1.14.0** \[libdap-3.19.1 : 
 besd-3.19.` : 
 olfs-1.17.0 : 
 ncWMS-2.2.2\]
 
## Overview

The hyrax-docker project can build the following Docker images:
* **hyrax**- A complete Hyrax server in a single container. It may be
    built with or without a bundled ncWMS.
* **besd** - The BackEndServer (BES) component of Hyrax.  
* **olfs** - The OLFS component of Hyrax, a Java Web Application deployed in Apache Tomcat.
* **ncwms** - The ncWMS application from our friends at the [Reading
    e-Science Centre](http://www.met.reading.ac.uk/resc/home/).

Each of these images can be run standalone; the last three can be
combined via docker compose or ansible.

The Hyrax service starts up providing access to the default (test)
data, but can easily be configured to serve data from the host machine
(see **_Using Hyrax docker to serve your data_**).

> NOTE: This code is based on work started by Gareth Williams at CSIRO
and contributed to OPeNDAP. We are grateful for their support.

## Quick Start

**_Build and run Dockerized Hyrax, serving your own data._**

For detailed information about each of the four Docker container
images, see the section **_Images_** below.

To build the single container hyrax, clone this project

```
git clone https://github.com/opendap/hyrax-docker
```
change directory to the desired hyrax release:
```
cd hyrax-docker/hyrax-1.13.5
```
and then use `docker build`
```
docker build -t hyrax_image hyrax
```
to include ncWMS in the image, use a build argument like this:
```
docker build -t hyrax_image --build-arg USE_NCWMS=true hyrax
```
To run the container:
```
docker run -h hyrax -p 8080:8080 --name=hyrax_container hyrax_image
```

Configure the _hyrax\_container_ so the server is accessible using
a port other than 8080, such as port 80, the default port for HTTP.
This can also be used to run several servers, each accessed using a
different port (e.g., you can have a development server running on
port 8080 and then use `-p 9090:8080` to bind the Hyrax in the docker
container to the localhost:9090).

To run the Dockerized Hyrax on port 80, use (note that docker is
started as the super user because only root can bind ports less than
1024).

```
sudo docker run -h hyrax -p 80:8080 --name=hyrax_container hyrax_image
```

To stop the container

```
docker stop hyrax_container
docker rm hyrax_container
```

where the argument to `docker stop` is the value passed in for the
`--name` parameter with `docker run`. The command `docker rm`
_removes_ the container and is needed only if you want to (re)start the
container with different values for any of the `docker run`
parameters.

## Using Hyrax docker to serve your data

To serve data other than the default data included with Hyrax/BES, use the
_volume_ option with `docker run` to map the path to data on your host
to `/usr/share/hyrax` in the Hyrax or BES container (`--volume <your path>:/usr/share/hyrax`).

```
docker run --hostname hyrax --port 8080:8080 --volume /home/mydata:/usr/share/hyrax --name=hyrax_container hyrax_image
```

## Server Logs & Serving Your Data

### docker run 

We can use volume mounts on the command line of the `docker run` command to collect the server logs on the local file system.

#### Example - Run Hyrax & collect logs.
```
cd hyrax-docker/hyrax-1.13.5
docker build -t hyrax --no-cache hyrax
prefix=`pwd`
docker run \
   --name hyrax \
   --publish 8080:8080 \
   --volume $prefix/logs:/var/log/tomcat \
   --volume $prefix/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs \
   --volume $prefix/logs:/var/log/bes \
   hyrax \
   -e support@erehwon.edu \
   -s \
   -n http://localhost:8080
```

And we can use the mounts to serve data from the Docker host filesystem.
#### Example - Run Hyrax, and serve local data.
```
cd hyrax-docker/hyrax-1.13.5
docker build -t hyrax --no-cache hyrax
prefix=`pwd`
docker run \
   --name hyrax \
   --publish 8080:8080 \
   --volume $prefix/local_data:/usr/share/hyrax \
   hyrax \
   -e support@erehwon.edu \
   -s \
   -n http://localhost:8080
```

#### Example - Run Hyrax & ncWMS, collect logs, serve local data.
```
cd hyrax-docker/hyrax-1.13.5
docker build -t hyrax_ncwms --build-arg USE_NCWMS=true --no-cache hyrax
prefix=`pwd`
docker run \
   --name hyrax \
   --publish 8080:8080 \
   --volume $prefix/local_data:/usr/share/hyrax \
   --volume $prefix/logs:/var/log/tomcat \
   --volume $prefix/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs \
   --volume $prefix/logs:/var/log/bes \
   --volume $prefix/logs:/root/.ncWMS2/logs \
   hyrax_ncwms \
   -e support@erehwon.edu \
   -s \
   -n http://localhost:8080
```




### docker-compose
The docker compose files contain volume mounts that collect the various server logs onto the local file system. There also (disabled) examples of using mounts to map the BES cache onto the host filesystem and to supplant the default BES configuration with one from the host filesystem.

For example, this YML snippet:
```
    volumes:
     - ./logs/olfs_tomcat:/usr/local/tomcat/logs
     - ./logs:/usr/local/tomcat/webapps/opendap/WEB-INF/conf/logs
```
Maps the tomcat logs to `./logs/olfs_tomcat` and the various OLFS log files to `./logs`

See the project YML for more:
 * developer.yml 
 * hyrax.yml     
 * hyrax_wms.yml 


## Images

**_Performance Note:_**_We performed a rudimentary speed check comparing the single container Hyrax with the two container version launched by using docker-compose and the hyrax.yml file. Our results (below) indicated that, for our test, there was no significant performance difference between the two. YMMV._

````
one_container_times:  n=100, min=  129.96,  mean=  131.41 +/-  0.54,  max=  133.07
    
two_container_times   n=100, min=   82.90,  mean=  126.42 +/- 13.23,  max=  133.03
````

### hyrax

This image contains a complete Hyrax server. Currently based on
**CentOS-7** and **Tomcat-7** installed using _yum_.

#### build arguments

* **USE_NCMWS** - Setting the value of the argument to "true"
(`--build-arg USE_NCWMS=true`) will cause the ncWMS application to be
included in the container.

* **DEVELOPER_MODE** - Setting the value of the argument to "true"
(`--build-arg DEVELOPER_MODE=true`) instructs the build to insert
default authentication credentials into the ncWMS admin interface so
that it maybe be accessed in the running container. Otherwise the
ncWMS admin page is unreachable and not required as its configuration
is copied into the image during the build.

#### Environment Variables and Command Line Arguments

* **SERVER_HELP_EMAIL (`-e`)** - The email address of the support
person for the service. This will be returned in error and help pages.

* **FOLLOW_SYMLINKS (`-s`)** - Instructs the server to follow symbolic
  links in the file system.

* **NCWMS_BASE (`-n`)** - The system needs to know the publicly
accessible service base for the ncWMS (something like
http://yourhost:8080). If all you want is to test it on your local
system then the default value of http://localhost:8080 will suffice.

* **JAVA_OPTS** - If JAVA_OPTS is defined in the container runtime 
environment, tomcat/olfs/ncWMS will include those options in the 
service start up.  There are many options that could be passed. Of 
particular note is –Xmx which sets the amount of memory available. 
ncWMS will not work properly with low memory limits. JAVA_OPTS can 
be set by normal methods: on the docker run command line, or in 
docker-compose configuration or in your own container layer if you 
build on the provided containers. (This from Gareth 11 Sept 2017.)

#### Command Line Examples:

##### Command Line Options Example
Launch Hyrax using command line switches to set the admin email to
(`-e support@erehwon.edu`), enable symbolic link traversal (`-s`),
and set the ncWMS service base to (`-n http://foo.bar.com:8080`)

```
docker run                      \
    --name hyrax                \
    --publish 8080:8080            \
    hyrax_image                 \
    -e support@erehwon.edu      \
    -s                          \
    -n http://foo.bar.com:8080
```

##### Environment Variables Example
Launch Hyrax using command line defined environment variables to set
the admin email to (`-e SERVER_HELP_EMAIL=support@foo.com`), enable
symbolic link traversal (`-s`), and set the ncWMS service base to
(`-e NCWMS_BASE=http://foo.bar.com`)

```
docker run \
    --name hyrax \
    --publish 8080:8080 \
    --env FOLLOW_SYMLINKS=true \
    --env SERVER_HELP_EMAIL=support@foo.com \
    --env NCWMS_BASE=http://foo.bar.com \
    hyrax_image
```

> NOTE: The environment variables are set to the left of the image
name. The command line switches occur AFTER the image name.

##### The Whole Enchilada
In this example we use the command line parameters to condition the server. We specify a read-only volume for data, 3 read-write  volumes for collecting logs on the local disk, and finally mount our
local BES configuration onto the Docker BES instance configuration.
```
docker run \
    --name hyrax \
    --publish 8080:8080 \
    --volume  /usr/share/data:/usr/share/hyrax:ro  \
    --volume /tmp/logs/tomcat:/var/log/tomcat \
    --volume /tmp/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs \
    --volume /tmp/logs:/var/log/bes \
    --volume /etc/bes:/etc/bes \
    hyrax \
    -e support@erehwon.edu \
    -s \
    -n http://localhost:8080
```

And again but this time using command line set enironment variables. Same result as just above.

```
docker run \
    --name hyrax \
    --publish 8080:8080 \
    --volume  /usr/share/data:/usr/share/hyrax:ro  \
    --volume /tmp/logs/tomcat:/var/log/tomcat \
    --volume /tmp/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs \
    --volume /tmp/logs:/var/log/bes \
    --volume /etc/bes:/etc/bes \
    --env FOLLOW_SYMLINKS=true \
    --env SERVER_HELP_EMAIL=support@foo.com \
    --env NCWMS_BASE=http://foo.bar.com \
    hyrax_image
```
### Advanced Examples
In the event that greater control of the Hyrax configuration is desired, or additional disk space is required for the various BES caching activities one may utilize volume mounts to address these issues.

#### Map BES cache to host filesystem

```
docker run \
    --name hyrax \
    --publish 8080:8080 \
    --volume /tmp/bes_cache:/tmp  \
    --volume /usr/share/data:/usr/share/hyrax:ro  \
    --volume /tmp/logs/tomcat:/var/log/tomcat \
    --volume /tmp/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs \
    --volume /tmp/logs:/var/log/bes \
    --env FOLLOW_SYMLINKS=true \
    --env SERVER_HELP_EMAIL=support@foo.com \
    --env NCWMS_BASE=http://foo.bar.com \
    hyrax_image
```
_Annontation:_

- ```--volume /tmp/bes_cache:/tmp```: Maps the docker container's /tmp dir to the docker host directory /tmp/bes_cache
- ```--volume /usr/share/data:/usr/share/hyrax:ro```: Maps the docker container's Hyrax data directory to the docker host directory ```/usr/share/data```
- ```--volume /tmp/logs/tomcat:/var/log/tomcat```: Maps the docker container's Tomcat logs directory to the docker host directory ```/tmp/logs/tomcat```
- ```--volume /tmp/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs```: Maps the docker container's OLFS logs to the docker host directory ```/tmp/logs```
- ```--volume /tmp/logs:/var/log/bes```: Maps the docker container's BES log files to the docker host directory ```/tmp/logs```

#### Replace default BES configuration 

```
docker run \
    --name hyrax \
    --publish 8080:8080 \
    --volume /home/roger/bes:/etc/bes  \
    --volume /usr/share/data:/usr/share/hyrax:ro  \
    --volume /tmp/logs/tomcat:/var/log/tomcat \
    --volume /tmp/logs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf/logs \
    --volume /tmp/logs:/var/log/bes \
    --env FOLLOW_SYMLINKS=true \
    --env SERVER_HELP_EMAIL=support@foo.com \
    --env NCWMS_BASE=http://foo.bar.com \
    hyrax_image
```
_Annontation:_

- ```--volume /home/roger/bes:/etc/bes```: Replaces the docker container's BES configuration with one held in the docker host file system directory ```/home/roger/bes```

#### Replace default BES & OLFS configuration 

```
docker run \
    --name hyrax \
    --publish 8080:8080 \
    --volume /home/roger/bes:/etc/bes  \
    --volume /home/roger/olfs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf \
    --volume /usr/share/data:/usr/share/hyrax:ro  \
    --volume /tmp/logs/tomcat:/var/log/tomcat \
    --volume /tmp/logs:/var/log/bes \
    --env FOLLOW_SYMLINKS=true \
    --env SERVER_HELP_EMAIL=support@foo.com \
    --env NCWMS_BASE=http://foo.bar.com \
    hyrax_image
```
_Annontation:_

- ```--volume /home/roger/bes:/etc/bes```: Replaces the docker container's BES configuration with one held in the docker host file system directory ```/home/roger/bes```
- ```--volume /home/roger/olfs:/var/lib/tomcat/webapps/opendap/WEB-INF/conf```: Replaces the docker container's OLFS configuration with one held in the docker host file system directory ```/home/roger/olfs```

    

### besd

This CentOS-7 based image contains just the BES component of the Hyrax server.

#### build arguments (_none_)

#### Environment Variables and Command Line Arguments

* **SERVER_HELP_EMAIL (`-e`)** - The email address of the support
  person for the service. This will be returned in error and help
  pages.

* **FOLLOW_SYMLINKS (`-s`)** - Instructs the server to follow symbolic
  links in the file system.

#### Command Line Examples:

Launch besd using command line switches to set the admin email to (`-e
support@erehwon.edu`) and enabling symbolic link traversal (`-s`)

```
docker run --name besd -p 10022:10022 besd_image -e support@erehwon.edu -s
```

Launch besd using command line defined environment variables to set
the admin email to (`-e SERVER_HELP_EMAIL=support@foo.com`) and enable
symbolic link traversal (`-s`)

```
docker run --name besd -p 10022:10022 -e FOLLOW_SYMLINKS=true -e SERVER_HELP_EMAIL=support@foo.com besd_image
```

> NOTE: The environment variables are set to the left of the image
name. The command line switches occur AFTER the image name.

### olfs

This image, based on the UNIDATA security hardened Tomcat, contains just
the OLFS web application.

> NOTE: _This image does not run Tomcat in its 'security' mode_

#### build arguments

* **USE_NCMWS** - Setting the value of the argument to "true"
 (`--build-arg USE_NCWMS=true`) will cause the OLFS to be configured
 to provide ncWMS links, but will not include the ncWMS application in
 the image.

#### Environment Variables and Command Line arguments

* **NCWMS_BASE (`-n`)** - The system needs to know the publicly
accessible service base for ncWMS (something like
http://yourhost:8080). If all you want is to test it on your local
system then the default value of http://localhost:8080 will suffice.

#### Command Line Examples:

Launch the olfs using command line switches to set the ncWMS service
base to (`-n http://foo.bar.com:8080`)

```
docker run --name olfs -p 8080:8080 olfs_image -n http://foo.bar.com:8080
```

Launch the olfs using command line defined environment variables to
set the ncWMS service base to (`-e NCWMS_BASE=http://foo.bar.com`)

```
docker run --name besd -p 8080:8080 -e NCWMS_BASE=http://foo.bar.com olfs_image
```

### ncwms

This image, based on the official Tomcat:8 image, contains just the
ncWMS-2.2.2 web application.

> NOTE: _This image does not run Tomcat in its 'security' mode_

#### build arguments

* **DEVELOPER_MODE** - Setting the value of the argument to "true"
 (`--build-arg DEVELOPER_MODE=true`) instructs the build to insert
 default authentication credentials into the ncWMS admin interface so
 that it maybe be accessed in the running container. Otherwise the
 ncWMS admin page is unreachable as it is not required at runtime. Its
 configuration is copied into the image during the build.

#### Environment Variables and Command Line arguments
_None_

#### Command Line Examples:

Launch the ncwms using command line switches to set the ncWMS service
base to (`-n http://foo.bar.com:8080`)

```
docker run --name ncwms -p 8080:8080 ncwms_image
```

## Docker-Compose 

We provide several YAML files for docker-compose. All of the files are
written to load the file `./local.env` in order to set the environment
variables described above. A template for this file may be found in
`./local.env.orig`, copy it to `./local.env` and edit that to
configure your Hyrax instance.

### hyrax.yml

This builds and launches a composed Hyrax made up of a single **besd**
and a single **olfs** container. Log directories for the OLFS, Tomcat,
and the BES are mapped to the `./logs` directory.

**Start:** `docker-compose -f hyrax.yml up`

**Stop:** `docker-compose -f hyrax.yml down --remove-orphans`

### hyrax_wms.yml

This builds and launches a composed Hyrax made up of a single
**besd**, a single **olfs**, and a single **ncWMS* container. Log
directories for the OLFS, Tomcat, and the BES are mapped the `./logs`
directory.

**Start:** `docker-compose -f hyrax_wms.yml up`

**Stop:** `docker-compose -f hyrax_wms.yml down --remove-orphans`

### developer.yml 

This builds and launches a **hyrax_wms**, but in developer mode. Log
directories the OLFS, Tomcat, and the BES are mapped to the `./logs`
directory.

**Start:** `docker-compose -f developer.yml up`

**Stop:** `docker-compose -f developer.yml down --remove-orphans`

## Ansible

It's possible that the existing **playbook.yml** file will work, but
it has not been tested.

# License

Copyright (c) 2017 OPeNDAP, Inc.

Authors: Nathan David Potter <ndp@opendap.org>,
Dan Holloway <dholloway@opendap.org>,
James Gallagher <jgallagher@opendap.org>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 3.0 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

You can contact OPeNDAP, Inc. at PO Box 112, Saunderstown, RI. 02874-0112.

# Acknowledgements

Based on https://bitbucket.csiro.au/projects/ASC/repos/hyrax-docker/,
Dec 19, 2016, by gareth.williams@csiro.au. That project was licensed
under a CSIRO variation of a MIT / BSD Open Source License. The
license text is in the file CSIRO\_MIT\_LICENSE

> NOTE: Gareth wrote: Ideas have been drawn from
https://github.com/Unidata/thredds-docker and various other
contributions on _dockerhub_, including the official _postgres_
container's exemplar use of variables with an entrypoint.
