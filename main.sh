#!/bin/bash

# CHANGeTHESE
auth_email=$CLOUD_FLARE_EMAIL
auth_key=$CLOUD_FLARE_API_KEY
zone_identifier=$CLOUD_FLARE_ZONE
record_domain=$RECORD_DOMAIN

deployment=$DEPLOYMENT
namespace=$NAMESPACE

# SCRIPT START
echo "[Cloudflare] Move to the right namespace"

kubectl config use-context $KUBE_CONTEXT

echo "[Cloudflare] Get the LoadBalancer"

elb_value=$(kubectl get service -n $namespace $deployment -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo $elb_value

export RECORD_VALUE=$elb_value

