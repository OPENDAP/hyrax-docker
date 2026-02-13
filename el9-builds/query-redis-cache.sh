#!/bin/bash

REDIS="redis-cli -h sit-redis.hmhtzc.0001.usw2.cache.amazonaws.com -p 6379"

mapfile -t keys < <($REDIS --scan --pattern "hyrax_session:redisson:tomcat_session:*")

echo "Total keys: ${#keys[@]}"

for key in "${keys[@]}"; do
  echo "Processing $key"
  # e.g., fetch metadata
  $REDIS HGETALL "$key"
done
