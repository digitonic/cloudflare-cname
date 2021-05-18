#!/bin/bash

auth_email=$CLOUD_FLARE_EMAIL
auth_key=$CLOUD_FLARE_API_KEY
zone_identifier=$CLOUD_FLARE_ZONE
record_domain=$RECORD_DOMAIN
record_name=$RECORD_NAME
REGEX='^([^.]+)'

namespace=$NAMESPACE

error_exit()
{
  echo "[Cloudflare] Error:"
  echo "$1"
  exit 1
}

run_delete_record()
{
  # Seek for the record
  record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_search" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json")

  # Set therecord identifier from result
  record_identifier=$(echo "$record" | grep -Po '(?<="id":")[^"]*' | head -1)
  echo "[Cloudflare] Record id found: $record_identifier"
  # The execution of delete
  delete=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json")

  # The moment of truth
  if [[ $delete == *"\"success\":false"*  ]]; then
    error_exit "[Cloudflare] Delete failed. DUMPING RESULTS:\n $delete"
  else
    echo -e  "[Cloudflare] Record has been deleted from Cloudflare.\n https://$record_search \n"
    exit 0
  fi
}


if [ -z "${DEPLOYMENT_TARGET}" ];
then
  echo "[Cloudflare] DEPLOYMENT_TARGET is unset so DEPLOYMENT will be used: '$DEPLOYMENT'";
  deployment_target=$DEPLOYMENT
else
  echo "[Cloudflare] DEPLOYMENT_TARGET is set to '$DEPLOYMENT_TARGET' and this will be used";
  deployment_target=$DEPLOYMENT_TARGET
fi

echo "[Cloudflare] Move to the right namespace"

kubectl config use-context "$KUBE_CONTEXT"

echo "[Cloudflare] Get the LoadBalancer"

echo "kubectl get service -n $namespace $deployment_target -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"

elb_value=$(kubectl get service -n $namespace $deployment_target -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo $elb_value

export record_value=$elb_value

echo "[Cloudflare] Update or create the elb"

record_search="$record_name$record_domain"

[[ $record_search =~ $REGEX ]]

matched=${BASH_REMATCH[1]}

echo "[Cloudflare] Name of the record: $matched"

echo "[Cloudflare] Generated record content is : $record_search"

if [[ $DELETE_RECORD == 1 ]]; then
  run_delete_record
  exit 0
else
  echo "[Cloudflare] Skipping DELETE_RECORD: $DELETE_RECORD !"
fi

# Seek for the record
record=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?name=$record_search" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json")

# Can't do anything without both record
if [[ $record == *"\"count\":0"* ]]; then
  create=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$matched\",\"content\":\"$record_value\"}")
  # The moment of truth
  if [[ $create == *"\"success\":false"* ]]; then
    error_exit "[Cloudflare] Creation failed. DUMPING RESULTS:\n$create"
  else
    echo -e "[Cloudflare] Record created in Cloudflare. \n https://$record_search \n"
    exit 0
  fi
fi

# Set therecord identifier from result
record_identifier=$(echo "$record" | grep -Po '(?<="id":")[^"]*' | head -1)
echo "[Cloudflare] Record id found: $record_identifier"
# The execution of update
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" -H "X-Auth-Email: $auth_email" -H "X-Auth-Key: $auth_key" -H "Content-Type: application/json" --data "{\"type\":\"CNAME\",\"proxied\":true,\"name\":\"$matched\",\"content\":\"$record_value\"}")

# The moment of truth
if [[ $update == *"\"success\":false"*  ]]; then
  error_exit "[Cloudflare] Update failed. DUMPING RESULTS:\n $update"
else
  echo -e  "[Cloudflare] Record has been synced to Cloudflare.\n https://$record_search \n"
  exit 0
fi
