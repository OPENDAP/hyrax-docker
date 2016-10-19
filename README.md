build and run docker containers for the hyrax bes and olfs
----------------------------------------------------------

The bes(d) has minimal alterations from the default centos rpm setup

The olfs has minor tweaks to find the besd, and a minimal ncWMS2 setup

There is duplicate setup for making it run. It can be driven by docker-compose
or ansible (with duplicate embedded docker-compose syntax).

Entrytpoint scripts are used to alter the key conf files on startup based on
environment variables, described below: 

The viewers.xml configuration for ncWMS2 requires specifying a client
accessible host:port combination, The default setting will result in godiva 
only working for clients on the localhost. 

OLFS_WMS_VIEWERS_HOSTPORT=localhost:8080

Key tunable parameters from /etc/bes/bes.conf can be altered with environment variables.
This could readily be extended for other tunables like cache size.

BES_HELP_EMAIL=help@replaceme

BES_SYMLINKS=Yes # No is the alternative option

To get environment variables to docker-compose (or the docker-compose settings
duplicated in the ansible playbook), an environment file names local.env must
be provided. There is a starting point in the repository at local.env.orig and
.gitignore is set to exclude local.env from the repository.

To run ansible:
```
ansible-playbook -i "localhost," -c local playbook.yml
```

or To run docker-compose:
```
docker-compose build
docker-compose up
# control-c to exit in this case or
docker-compose up -d
docker-compose down
```

ToDo:

  * feedback to opendap.org (and Reading and TPAC?) - started
    * how to run beslistener in the foreground and are all those options needed
    * link for current rpm was/is broken...
    * contribute this back
  * avoid duplication of docker-compose config if possible

License: The original author considers the content in this project to be
recipes/data intended to be shared, so a cc-by license is applied.
Embedded sed and perl code for manipulation of config data is not considered 
to be of particular novel value.

```
hyrax-docker (c) by contributors:
gareth.williams@csiro.au

hyrax-docker is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by/4.0/>.
```
