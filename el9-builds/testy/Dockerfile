###############################################################################################
# 
# Dockerfile for single container Hyrax
#
#
# Some shell state reference:
# set -f # "set -o noglob"  Disable file name generation using metacharacters (globbing).
# set -v # "set -o verbose" Prints shell input lines as they are read.
# set -x # "set -o xtrace"  Print command traces before executing command.
# set -e #  Exit on error.
#
# In general use "set -e" when running commands that matter and don't use
# it for debugging stuff.
#
# Set one or more individual labels
FROM rockylinux:9

RUN set -e && dnf update  -y


COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 8009
EXPOSE 8080
EXPOSE 8443
EXPOSE 10022
EXPOSE 11002

USER root

CMD ["-"]

