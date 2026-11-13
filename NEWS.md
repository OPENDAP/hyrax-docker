
---
## Hyrax-1.18.1 November 12, 2026

### Hyrax General
* Retired ncWMS integration from el9 production rules. Also a 
general ncWS purgative

### NGAP image
* Check for failure of the beslog2json.py pipe and restart if configured to do so.  (#186)
* Remove AWS creds support (aws cli is not installed)
* Better tomcat startup and pid detection
* Checking for bes.log issues on container startup.
* Updated get_instance_id code for using the IMDSv2 way

### CICD
* Added "--max-time 5" to all cURL invocations
* Switched to "tail -F" for the log tailing


---
# **Hyrax-1.18.0**:

## 🚀 Key Highlights & Version Updates


* **Security & Port Configuration:** Unexposed BES ports `10022` and `11002` (#176).

### Dependency & Build Fixes

* Upgraded Redisson to Version 4 (NGAP EL9 REDIS4 support, #171).

* Re-added Jackson dependencies (`2.21.+`) and configured Gradle to fail fast on build errors (#172).

* Updated build infrastructure to use **Java 17** for Gradle build steps.

* Switched Apache APR installation to use native `dnf` package management rather than a custom retrieval script (#163).


## 🤖 CI/CD & Automated Image Builds

The vast majority of the log consists of automated build triggers by **The-Robot-Travis**:

* **Multi-OS Docker Support:** Triggered parallel Docker container image builds targeting both **EL8** (running OLFS 1.18.x) and **EL9** (running Tomcat 11 and OLFS 1.18.x–1.19.x) environments.


* **Component Matrix Updates:** Incrementally built and tested updated core library components, including `libdap4` (v3.21.1 / v3.22.0), `bes` (v3.21.1 / v3.22.0), and `olfs` (v1.18.15 / v1.19.0).