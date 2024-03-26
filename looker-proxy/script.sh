#!/bin/bash

set -e

eval "$(jq -r '@sh "DOMAIN_NAME=\(.domain_name)"')"

IP_ADDRESS=$(dig +short ${DOMAIN_NAME})

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg ip_address "$IP_ADDRESS" '{"ip_address":$ip_address}'