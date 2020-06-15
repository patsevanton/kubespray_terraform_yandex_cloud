# Install k8s cluster with Kubespray on Yandex Cloud

## Register in Yandex Cloud

https://cloud.yandex.ru

## Install Terraform client 

https://learn.hashicorp.com/terraform/getting-started/install

## Install Ansible

https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

## Install Kubectl

https://kubernetes.io/docs/tasks/tools/install-kubectl/

## Install Helm

https://helm.sh/docs/intro/install/

## Install jq (small CLI utility for JSON parsing)

https://stedolan.github.io/jq/

## Clone Kubespray repo and install Kubespray requirements
```
$ git clone git@git.cloud-team.ru:ansible-roles/kubespray.git kubespray -b cloudteam
$ sudo pip3 install -r kubespray/requirements.txt
```

## Set Terraform variables
```
$ cp terraform/private.auto.tfvars.example terraform/private.auto.tfvars
$ vim terraform/private.auto.tfvars
```

## Create cloud resources and install k8s cluster
```
$ bash cluster_install.sh
```

## Copy generated config
```
$ mkdir -p ~/.kube && cp kubespray/inventory/mycluster/artifacts/admin.conf ~/.kube/config
```

## Deploy test app
```
$ kubectl apply -f manifests/test-app.yml
```

## Add hosts to your local hosts file
```
$ sudo sh -c "cat kubespray_inventory/etc-hosts >> /etc/hosts"
```

## Check external access to test app
```
$ curl hello.local
Hello from my-deployment-784598767c-7gjjs
```

# Cluster monitoring

## Install Kubernetes Dashboard
```
$ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
$ helm install --namespace monitoring --create-namespace -f manifests/dashboard-values.yml \
  kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard
$ kubectl apply -f manifests/dashboard-admin.yml
$ kubectl -n monitoring describe secret \
  $(kubectl -n monitoring get secret | grep admin-user | awk '{print $1}')
$ kubectl port-forward -n monitoring $(kubectl get pods -n monitoring \
  -l "app.kubernetes.io/name=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}") 9090
```
Go to http://localhost:9090 and use token for authentication

## Install Prometheus and Grafana
```
$ helm install --namespace monitoring --create-namespace -f manifests/prometheus-values.yml \
  prometheus stable/prometheus
$ helm install --namespace monitoring --create-namespace -f manifests/grafana-values.yml \
  grafana stable/grafana
```

### Access Prometheus UI

Go to http://prometheus.local

### Access Grafana UI
```
$ kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Go to http://grafana.local (user: admin, password: result of first command).
Add new data source with type "Prometheus" and url "http://prometheus-server".
Import a new dashboard to Grafana (grafana.com dashboard: https://grafana.com/dashboards/1621, Prometheus: created one).

# Logging

## Deploy Loghouse
```
$ helm repo add loghouse https://flant.github.io/loghouse/charts/
$ helm install --namespace loghouse --create-namespace -f manifests/loghouse-values.yml \
  loghouse loghouse/loghouse
```
Go to http://loghouse.local (login: admin, password: PASSWORD).

Try to search logs of test app with the query:
```
~app = "my-app"
```

# Cluster backup/restore

## Install Velero

https://velero.io/docs/v1.4/basic-install/

## Install and configure AWS plugin
```
$ velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.1.0 \
  --bucket backup-backet \
  --backup-location-config region=ru-central1-a,s3ForcePathStyle="true",s3Url=https://storage.yandexcloud.net \
  --snapshot-location-config region=ru-central1-a \
  --secret-file kubespray_inventory/credentials-velero
```

## Create backup and watch its status
```
$ velero backup create my-first-backup
$ velero backup get
```

## Delete test app
```
$ kubectl delete -f manifests/test-app.yml
```

## Restore backup and list restores
```
$ velero restore create --from-backup my-first-backup
$ velero restore get
```

# Destroy cluster

## Delete cloud resources
```
$ bash cluster_destroy.sh
```
