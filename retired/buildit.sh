#!/bin/bash
# Simple build script that has back in versioning - We can improve this but it works for now.

docker build -t bes-3.18.0-static besd
docker build -t olfs-1.16.3 olfs
