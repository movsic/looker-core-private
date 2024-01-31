# Debug commands

## Test the connectivity directly to looker core instance
curl --header "Host: ${LOOKER_CUSTOM_DOMAIN}" https://${LOOKER_IP_ADDRESS}/alive -v -k

## Build nginx docker container using cloud build
gcloud builds submit --substitutions=_DOMAIN_NAME=${DOMAIN_NAME},_IP_ADDRESS=${IP_ADDRESS} --config=looker-proxy/cloudbuild.yaml --project=${PROJECT_ID} ./looker-proxy

## TODOs
1. Check if global lb resources can be used instead regional 
1. Check if managed ssl cert can be used instead of google_compute_region_ssl_certificate 
    1. Compute SSL certificates are not supported with global INTERNAL_MANAGED load balancer
1. Seems like the problem with the lb-shared internal ip_address
1. Check private.lookerapp looker domain name

## Requirements
You need dig and jq installed on the machine where you'll run the terraform apply command
