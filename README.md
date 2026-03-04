# Hyrax docker

## Current Version: <font style="font-size: 300%;">**Hyrax-1.17.1**</font> [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14660548.svg)](https://doi.org/10.5281/zenodo.14660548)

**Hyrax-1.17.1** is composed of:

|                                                                                    ||
|:----------------------------------------------------------------------------------:| :---:|
| **[OLFS version 1.18.15](https://github.com/OPENDAP/olfs/releases/tag/1.18.15)** | [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14659391.svg)](https://doi.org/10.5281/zenodo.14659391)
| **[BES version 3.21.1](https://github.com/OPENDAP/bes/releases/tag/3.21.1)** |[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14655683.svg)](https://doi.org/10.5281/zenodo.14655683)
| **[libdap4 version 3.21.1](https://github.com/OPENDAP/libdap4/releases/tag/3.21.1)** | [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.14646648.svg)](https://doi.org/10.5281/zenodo.14646648)|


## <a name="contents"></a>Contents
* [Overview](#overview)
* [Quick Start](#quickstart)
* [Serving Your Data](#yerdata)
* [Server Logs](#serverlogs)
* [Docker Images](#images)
  * [hyrax](#hyrax-image)
  * [besd](#besd-image)
  * [olfs](#olfs-image)
  * [ncwms](#ncwms-image)
* [Docker-Compose](#dockercompose)
  * [hyrax](#hyrax-yml)
  * [hyrax-wms](#hyrax-wms-yml)
  * [developer](#developer-yml)
* [Ansible](#ansible)
* [License](#license)
* [Acknowledgements](#ack)

 
## <a name="overview"></a>Overview

The hyrax-docker project can build the following Docker images:
* **hyrax**- A complete Hyrax server in a single container. It may be
    built with or without a bundled ncWMS.
* **besd** - The BackEndServer (BES) component of Hyrax.  
* **olfs** - The OLFS component of Hyrax, a Java Web Application deployed in 
Apache Tomcat.
* **ncwms** - The ncWMS application from our friends at the [Reading
    e-Science Centre](http://www.met.reading.ac.uk/resc/home/).
* **ngap** - A specialization of the Hyrax server for deployment in
the NASA cloud. This variant is dependent on the injection of 
numerous configuration information at launch an is unlikely to be 
of use to people whoa are not directly involved with the NGAP
project.


Each of these images can be run standalone. The **besd**, **olfs**,
and the **ncwms** images may be combined via docker compose or ansible. 

>Note: We build and upload our official release containers 
> to Docker Hub. We also produce and publish to Docker Hub 
**snapshot** containers for every CI build of **hyrax**, **olfs**,
**besd**, and **ngap** images. While these CI build images have
> passed all of our various tests they are not official releases. 
> _Caveat Emptor_.

The default configuration has the Hyrax service start up providing
access to the default (test) data, but can easily be configured to 
serve data from the host machine
(see **_Using Hyrax docker to serve your data_**).

> NOTE: This code is based on work started by Gareth Williams at CSIRO
and contributed to OPeNDAP. We are grateful for their support.

## <a name="quickstart"> Quick Start

You can easily build your own Docker image of Hyrax using the material 
in this project. Alternatively, you can download offical images from 
our various DockerHub repositories. Both are discussed below.

### Get The Desired Image
#### Download

Probably the quickest way to get started is to _pull_ one of our images from 
Docker Hub and run that. Each of the docker hub pages has simple launch 
instructions for the associated image(s).
More elaborate instructions may be found below in this document.

_Hyrax Docker Hub Pages_
- [**Hyrax Data Server**](https://cloud.docker.com/u/opendap/repository/docker/opendap/hyrax)
- [**Hyrax Data Server + ncWMS2**](https://cloud.docker.com/u/opendap/repository/docker/opendap/hyrax_ncmws)
- [**besd**](https://cloud.docker.com/u/opendap/repository/docker/opendap/besd)
- [**olfs**](https://cloud.docker.com/u/opendap/repository/docker/opendap/olfs)


#### Build 

Build and run a dockerized Hyrax, serving your own data.

Each build is based on a _build recipe_ that specifies the binary
components to be used in the build. 

For our CI builds those components reside exclusively in a private
S3 bucket owned by OPeNDAP. In order to build using those recipes, 
one needs to have credentials to access the S3 bucket. Once you have configured
your AWS credentials (either using the AS configuratrion or envirnment 
variables) the`build_from_ci_recipe.sh` shell script will perform the retrieval
and docker build using the recipe supplied, or the most recent recipe in the 
`./el8-build-recipe` file.

Our official release builds can be (re)built by using one
of the recipes located in the _releases_ directory. The 
`build_from_release_recipe.sh` shell script located in this 
directory will build the latest release, or it can be told which
build recipe file to utilize as the only command line parameter
to the shell script.

For detailed information about each of the four Docker container
images, see the section **_Images_** below.

To build the single container hyrax, clone this project

```
git clone https://github.com/opendap/hyrax-docker
```
change directory to the top of the project:
```
cd hyrax-docker
```
and then use `build_from_release_recipe.sh`
```
./build_from_release_recipe.sh
```
To build the docker image using the latest release binaries located
at www.opendap.org/pub 

To build the release from a previous version, for example `1.16.8`:
```
./build_from_release_recipe.sh releases/hyrax-1.16.8-build-recipe
```
### Running The Server

To run the container:
```
docker run -d -h hyrax -p 8080:8080 --name=hyrax_container hyrax_image
```

To run the container with ncWMS you'll need to tell the server where the ncWMS service is located.
This can be done by utilizing the container's **<tt>-n</tt>** paramter to specify the endpoint like this:
```
docker run -d -h hyrax -p 8080:8080 --name=hyrax_container hyrax_image -n http://localhost:8080
```

> **TIP:** The value of **<tt>-n</tt>** should be the outward facing domain 
name / IP address of your Docker container. If you are running a 
container on your local system, then the example value of 
**<tt>http://localhost:8080 </tt>** should work well. If your Hyrax container is
running elsewhere (in AWS for example) you'll have to sort out what
the value should be. If the **<tt>-n</tt>**  parameter is omitted from 
the **<tt>docker run</tt>** command then the value used will be the 
value of **<tt>--build-arg NCWMS_BASE</tt>** from the **<tt>docker build</tt>** 
command. If no **<tt>NCWMS_BASE</tt>** was specified in the 
**<tt>docker build</tt>** command then the value defaults to 
**<tt>https://localhost:8080 </tt>** (note that this is an HTTPS transport URL)

To configure the _hyrax\_container_ so the server is accessible using
a port other than 8080, such as port 80, the default port for HTTP.
This can also be used to run several servers, each accessed using a
different port (e.g., you can have a development server running on
port 8080 and then use `-p 9090:8080` to bind the Hyrax in the docker
container to the localhost:9090).

To run the Dockerized Hyrax on port 80, use (note that docker is
started as the super user because only root can bind ports less than
1024).

```
sudo docker run -d -h hyrax -p 80:8080 --name=hyrax_container hyrax_image
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

##  <a name="yerdata"> Using Hyrax docker to serve your data

To serve data other than the default data included with Hyrax/BES, use the
_volume_ option with `docker run` to map the path to data on your host
to `/usr/share/hyrax` in the Hyrax or BES container (`--volume <your path>:/usr/share/hyrax`).

```
docker run --hostname hyrax --port 8080:8080 --volume /home/mydata:/usr/share/hyrax --name=hyrax_container hyrax_image
```

## <a name="serverlogs"> Server Logs & Serving Your Data

### docker run 

We can use volume mounts on the command line of the `docker run` command to collect the server logs on the local file system.

#### Example - Run Hyrax & collect logs.
```
cd hyrax-docker/hyrax-latest
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
cd hyrax-docker/hyrax-latest
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
cd hyrax-docker/hyrax-latest
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

## <a name="images"> Images

**_Performance Note:_**_We performed a rudimentary speed check comparing the single container Hyrax with the two container version launched by using docker-compose and the hyrax.yml file. Our results (below) indicated that, for our test, there was no significant performance difference between the two. YMMV._

````
one_container_times:  n=100, min=  129.96,  mean=  131.41 +/-  0.54,  max=  133.07
    
two_container_times   n=100, min=   82.90,  mean=  126.42 +/- 13.23,  max=  133.03
````

### <a name="hyrax-image"> hyrax

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
system then the value of http://localhost:8080 will suffice.

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
    --publish 8080:8080         \
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

### <a name="besd-image"> besd

**_Note_**: The _besd_, _olfs_, and _ncWMS_ containers are tested only minimally
by us at thsi time (Nov 2018) and are really for specialized cases wehre fine-grained
control over the server tiers is needed. You'll need to build these containers yourself.

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

### <a name="olfs-image"> olfs

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

### <a name="ncwms-image"> ncwms

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

## <a name="dockercompose"> Docker-Compose 

We provide several YAML files for docker-compose. All of the files are
written to load the file `./local.env` in order to set the environment
variables described above. A template for this file may be found in
`./local.env.orig`, copy it to `./local.env` and edit that to
configure your Hyrax instance.

### <a name="hyrax-yml"> hyrax.yml

This builds and launches a composed Hyrax made up of a single **besd**
and a single **olfs** container. Log directories for the OLFS, Tomcat,
and the BES are mapped to the `./logs` directory.

**Start:** `docker-compose -f hyrax.yml up`

**Stop:** `docker-compose -f hyrax.yml down --remove-orphans`

### <a name="hyrax-wms-yml"> hyrax_wms.yml

This builds and launches a composed Hyrax made up of a single
**besd**, a single **olfs**, and a single **ncWMS* container. Log
directories for the OLFS, Tomcat, and the BES are mapped the `./logs`
directory.

**Start:** `docker-compose -f hyrax_wms.yml up`

**Stop:** `docker-compose -f hyrax_wms.yml down --remove-orphans`

### <a name="developer-yml"> developer.yml 

This builds and launches a **hyrax_wms**, but in developer mode. Log
directories the OLFS, Tomcat, and the BES are mapped to the `./logs`
directory.

**Start:** `docker-compose -f developer.yml up`

**Stop:** `docker-compose -f developer.yml down --remove-orphans`

## <a name="ansible"> Ansible

It's possible that the existing **playbook.yml** file will work, but
it has not been tested.


# <a name="license"> License

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

# <a name="ack"> Acknowledgements

Based on https://bitbucket.csiro.au/projects/ASC/repos/hyrax-docker/,
Dec 19, 2016, by gareth.williams@csiro.au. That project was licensed
under a CSIRO variation of a MIT / BSD Open Source License. The
license text is in the file CSIRO_MIT_LICENSE

> NOTE: Gareth wrote: Ideas have been drawn from
https://github.com/Unidata/thredds-docker and various other
contributions on _dockerhub_, including the official _postgres_
container's exemplar use of variables with an entrypoint.

