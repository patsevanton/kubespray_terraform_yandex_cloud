#!/bin/bash

set -e

cd terraform
TF_IN_AUTOMATION=1 terraform init
TF_IN_AUTOMATION=1 terraform apply -auto-approve
bash generate_inventory.sh > ../kubespray_inventory/hosts.ini
bash generate_credentials_velero.sh > ../kubespray_inventory/credentials-velero

cd ../
rm -rf kubespray/inventory/mycluster
cp -rfp kubespray_inventory kubespray/inventory/mycluster

cd kubespray
ansible-playbook -i inventory/mycluster/hosts.ini --become cluster.yml

cd ../terraform
printf "******************************************\n"
printf "Load balancer public IP: "
terraform output -json load_balancer_public_ip | jq -j ".[0]"
printf "\n******************************************\n"

MASTER_1_PRIVATE_IP=$(terraform output -json instance_group_masters_private_ips | jq -j ".[0]")
MASTER_1_PUBLIC_IP=$(terraform output -json instance_group_masters_public_ips | jq -j ".[0]")

sed -i -- "s/$MASTER_1_PRIVATE_IP/$MASTER_1_PUBLIC_IP/g" ../kubespray/inventory/mycluster/artifacts/admin.conf
