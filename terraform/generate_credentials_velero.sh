#!/bin/bash

set -e

printf "[default]\n"
printf "aws_access_key_id="
terraform output -json static-key-access-key | jq -j "."
printf "\n"
printf "aws_secret_access_key="
terraform output -json static-key-secret-key | jq -j "."
printf "\n"
