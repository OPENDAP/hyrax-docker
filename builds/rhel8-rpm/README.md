# Support for building RPM packages for RHEL 8

This directory contains a Dockerfile that can be used to build a Rocky8
VM that can then be used to build our C++ software and produce RPM packages.

Run ```docker build -t rocky8-rpm-builder .``` to build the Docker image.
