#!/bin/bash


# Stop the server
docker container stop olfs besd

# Cleanup the containers
docker container rm olfs besd 
