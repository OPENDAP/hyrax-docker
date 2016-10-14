build and run docker containers for the hyrax bes and olfs
----------------------------------------------------------

The bes(d) has minimal alterations from the default centos rpm setup

The olfs has minor tweaks to find the besd, and a minimal ncWMS2 setup

There is duplicate setup for making it run. It can be driven by docker-compose
or ansible.  With docker-compose.yml in the current form, the images need to be
built before docker-compose can be used.  That makes using ansible attractive.

As the viewers.xml configuration for ncWMS2 requires specifying a client
accessible host:port combination, there is a script prime.sh which must be run
before the olfs image can be built.  It takes a single argument - the host:port
combination used to replace the default localhost:8080

```
sh ./prime.sh data.my.com:80
```

To run ansible:
```
ansible-playbook -i "localhost," -c local playbook.yml
```

or To run docker-compose:
```
docker-compose up
```

ToDo:

  * feedback to opendap.org (and Reading and TPAC?) - started
    * how to run beslistener in the foreground and are all those options needed
    * link for current rpm was/is broken...
    * contribute this back
    * how to remove the requirement to embed the host address in viewers.xml - worked around with prime.sh
  * enable symlinks in bes (sed -i ...)

License: The author considers the content in this project to be recipes intended to be shared so a cc-by license is applied.

```
hyrax-docker (c) by gareth.williams@csiro.au

hyrax-docker is licensed under a
Creative Commons Attribution 4.0 International License.

You should have received a copy of the license along with this
work.  If not, see <http://creativecommons.org/licenses/by/4.0/>.
```
