#!/bin/bash

set -e

eval "$(jq -r '@sh "GIT_DOMAIN_NAME=\(.git_domain_name)"')"

GIT_IP_ADDRESS=$(dig +short ${GIT_DOMAIN_NAME})

# Safely produce a JSON object containing the result value.
# jq will ensure that the value is properly quoted
# and escaped to produce a valid JSON string.
jq -n --arg git_ip_address "$GIT_IP_ADDRESS" '{"git_ip_address":$git_ip_address}'