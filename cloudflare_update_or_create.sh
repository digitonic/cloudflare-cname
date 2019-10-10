#!/bin/bash

record_search="$record_name.$record_domain"

# SCRIPT START
echo "[Cloudflare] Check Initiated"


echo "Generated record is : $record_search"

# Seek for therecord
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_search" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json")

# Can't do anything without both record
if [[ $record == *"\"count\":0"* ]]; then
  echo "[Cloudflare] Dual stack records do not exist, creating one"
  create=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$record_name\",\"content\":\"$record_value\"}")
  # Themoment of truth
  if [[ $create == *"\"success\":false"* ]]; then
    >&2 echo -e "[Cloudflare] Creation failed. DUMPING RESULTS:\n$create"
    exit 1
  else
    >&2 echo -e "Record created in Cloudflare. \n $create"
    exit 1
  fi
fi

# Set therecord identifier from result
record_identifier=$(echo "$record" | grep -Po '(?<="id":")[^"]*' | head -1)

# Theexecution of update
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$record_name\",\"content\":\"$record_value\"}")

# Themoment of truth
if [[ $update == *"\"success\":false"*  ]]; then
  >&2 echo -e "[Cloudflare] Update failed. DUMPING RESULTS:\n $update"
  exit 1
else
  >&2 echo -e "[Cloudflare] Record has been synced to Cloudflare.\n $update"
fi