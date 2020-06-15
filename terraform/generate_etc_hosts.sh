#!/bin/bash

set -e

terraform output -json load_balancer_public_ip | jq -j ".[0]"
printf " hello.local prometheus.local grafana.local loghouse.local\n"
