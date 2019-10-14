#!/bin/bash

auth_email=$CLOUD_FLARE_EMAIL
auth_key=$CLOUD_FLARE_API_KEY
zone_identifier=$CLOUD_FLARE_ZONE
record_domain=$RECORD_DOMAIN
record_name=$RECORD_NAME

deployment=$DEPLOYMENT
namespace=$NAMESPACE

error_exit()
{
  echo "[Cloudflare] Error:"
  echo "$1"
  exit 1
}

echo "[Cloudflare] Move to the right namespace"

kubectl config use-context "$KUBE_CONTEXT"

echo "[Cloudflare] Get the LoadBalancer"

elb_value=$(kubectl get service -n $namespace $deployment -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo $elb_value

export record_value=$elb_value

echo "[Cloudflare] Update or create the elb"

record_search="$record_name.$record_domain"

echo "[Cloudflare] Starting checks"


echo "[Cloudflare] Generated record is : $record_search \n"

# Seek for therecord
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_search" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json")

# Can't do anything without both record
if [[ $record == *"\"count\":0"* ]]; then
  create=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$record_name\",\"content\":\"$record_value\"}")
  # Themoment of truth
  if [[ $create == *"\"success\":false"* ]]; then
    error_exit "[Cloudflare] Creation failed. DUMPING RESULTS:\n$create"
  else
    echo -e "[Cloudflare] Record created in Cloudflare. \n https://$record_search \n"
    exit 0
  fi
fi

# Set therecord identifier from result
record_identifier=$(echo "$record" | grep -Po '(?<="id":")[^"]*' | head -1)

# Theexecution of update
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"id\":\"$zone_identifier\",\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$record_name\",\"content\":\"$record_value\"}")

# Themoment of truth
if [[ $update == *"\"success\":false"*  ]]; then
  error_exit "[Cloudflare] Update failed. DUMPING RESULTS:\n $update"
else
  echo -e  "[Cloudflare] Record has been synced to Cloudflare.\n https://$record_search \n"
  exit 0
fi


