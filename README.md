# Install k8s cluster with Kubespray on Yandex Cloud

## Install YC CLI

https://cloud.yandex.ru/docs/cli/quickstart

You need to register account also: https://cloud.yandex.ru

## Install Terraform Client 

https://learn.hashicorp.com/terraform/getting-started/install

## Install jq (small CLI utility for JSON parsing)

https://stedolan.github.io/jq/

## Install Ansible

https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html

## Set Terraform variables
```
$ cd terraform
$ cp private.auto.tfvars.example private.auto.tfvars
$ vim private.auto.tfvars
```

## Clone Kubespray repo and install Kubespray requirements
```
$ git clone git@git.cloud-team.ru:ansible-roles/kubespray.git kubespray -b cloudteam
$ cd kubespray
$ sudo pip3 install -r requirements.txt
$ cd ../
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

## Check external access to test app
```
$ curl hello-world.info  --resolve hello-world.info:80:[load-balancer-public-ip]
Hello from my-deployment-784598767c-7gjjs
```

# Cluster monitoring

## Install Kubernetes Dashboard
```
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.1/aio/deploy/recommended.yaml
$ kubectl apply -f manifests/dashboard-admin.yml
$ kubectl -n kubernetes-dashboard describe secret \
  $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}')
$ kubectl proxy
```
Go to http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
and use token for authentication

## Install Prometheus and Grafana
```
$ helm install prometheus stable/prometheus -f manifests/prometheus-values.yml
$ helm install grafana stable/grafana
```

### Access Prometheus UI
```
$ kubectl port-forward $(kubectl get pods -l "app=prometheus,component=server" -o jsonpath="{.items[0].metadata.name}") 9090
```
Go to http://localhost:9090

### Access Grafana UI
```
$ kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
$ kubectl port-forward $(kubectl get pods -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].metadata.name}") 3000
```

Go to http://localhost:3000 (user: admin, password: result of first command).
Add new data source with type "Prometheus" and url "http://prometheus-server".
Import a new dashboard to Grafana (grafana.com dashboard: https://grafana.com/dashboards/1621, Prometheus: created one).

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

# Logging

## Deploy Loghouse
```
$ helm repo add loghouse https://flant.github.io/loghouse/charts/
$ helm install --namespace loghouse --create-namespace \
  -f manifests/loghouse-values.yml loghouse loghouse/loghouse
$ kubectl port-forward -n loghouse $(kubectl get pods -n loghouse -l "component=loghouse" \
  -o jsonpath="{.items[0].metadata.name}") 4000:80
```
Go to http://localhost:4000 (login: admin, password: PASSWORD)

Try to search logs of test app with the query:
```
~app = "my-app"
```

# Destroy cluster

## Delete cloud resources
```
$ bash cluster_destroy.sh
```
