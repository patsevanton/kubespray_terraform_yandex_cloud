#!/bin/bash

set -e

rm -rf kubespray/inventory/mycluster

cd terraform
TF_IN_AUTOMATION=1 terraform destroy -auto-approve
