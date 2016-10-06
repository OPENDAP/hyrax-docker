build and run docker containers for the hyrax bes and olfs
----------------------------------------------------------

The bes(d) has minimal alterations from the default centos rpm setup

The olfs has minor tweaks to find the besd, and a minimal ncWMS2 setup (broken!).

There is duplicate setup for making it run. It can be driven by docker-compose or ansible.
With docker-compose.yml in the current form, the images need to be built before docker-compose can be used.
That makes using ansible attractive.

```
ansible-playbook -i "localhost," -c local playbook.yml
```

ToDo:

  * Make ncWMS2 and godiva3 work (close - maybe Ids issue and terminology change)
  * feedback to opendap.org (and Reading and TPAC?)
    * how to run beslistener in the foreground and are all those options needed
    * link for current rpm was/is broken...
    * contribute this back
    * how to remove the requirement to embed the host address in viewers.xml
  * enable symlinks in bes (sed -i ...)

