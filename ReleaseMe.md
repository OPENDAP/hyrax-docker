# ReleaseMe! - _Docker image/container release instructions for hyrax and its components._




# <a name="makerelease"> Making release for new versions of Hyrax.

Copy _hyrax-latest_ to _hyrax-**version**_ and edit the _Dockerfiles_ in
the _hyrax_, _besd_, _olfs_ and _ncWMS_ directories. Generally, only
the version numbers for the packages need to be edited. Look for:
```
LABEL org.opendap.hyrax.version="1.15.1"
# 24 September 2018
LABEL org.opendap.hyrax.release-date="2018-11-26"
LABEL org.opendap.hyrax.version.is-production="true"
```
and
```
ENV HYRAX_VERSION=1.15
ENV LIBDAP_VERSION=3.20.1-1
ENV BES_VERSION=3.20.1-1
ENV OLFS_VERSION=1.18.1
```

Update the ```README.md``` file and follow the instructions contained within to 
build and push.

# License

Copyright (c) 2019 OPeNDAP, Inc.

Authors: Nathan David Potter <ndp@opendap.org>,
