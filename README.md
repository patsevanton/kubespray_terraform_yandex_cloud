# Install k8s cluster with Kubespray on Yandex Cloud

## Register in Yandex Cloud

https://cloud.yandex.ru

## Install Yandex.Cloud (CLI) 
```
$ curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

## Create profile Yandex Cloud

https://cloud.yandex.ru/docs/cli/quickstart

## Install binenv

https://github.com/devops-works/binenv

## Install Terraform client 

```
$ binenv install terraform
```

## Install Kubectl

```
$ binenv install kubectl
```

## Install Helm

```
$ binenv install helm
```

## Install jq (small CLI utility for JSON parsing)

```
$ sudo apt install jq
```

## Install pip3 and git
```
$ sudo apt install python3-pip git
```

## Clone Kubespray repo and install Kubespray requirements
```
$ wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.14.2.tar.gz
$ tar -xvzf v2.14.2.tar.gz
$ mv kubespray-2.14.2 kubespray
$ sudo pip3 install -r kubespray/requirements.txt
```

## Set Terraform variables
```
$ cp terraform/private.auto.tfvars.example terraform/private.auto.tfvars
$ yc config list
$ vim terraform/private.auto.tfvars
```

## Рассмотрим k8s-cluster.tf в web интерфейсе Яндекс облака

```
resource "yandex_vpc_network" "k8s-network" {
  name = "k8s-network"
}
```

Ресурс yandex_vpc_network находится в разделе Virtual Private Cloud

![](https://habrastorage.org/webt/sm/kn/fy/smknfygungqfljeethka7jkwmlu.png)

Ресурс "yandex_vpc_subnet" "k8s-subnet-1" находится в разделе Virtual Private Cloud в разделе k8s-network

![image-20210824161620960](C:\Users\Anton_Patsev\AppData\Roaming\Typora\typora-user-images\image-20210824161620960.png)

Ресурс "yandex_iam_service_account" находится в каталоге, где вы создаете инфраструктуру в разделе Сервисные аккаунты. 

![](https://habrastorage.org/webt/sv/bd/2b/svbd2bb0rt6mb8bchjc1s2e1eze.png)

Ресурс "yandex_compute_instance_group" находится в разделе Compute Cloud в разделе Группы виртуальных машин

![](https://habrastorage.org/webt/ao/tt/t-/aottt-hsr8s-roxabhjednimf7c.png)

Ресурс yandex_storage_bucket находится в разделе Object Storage

## Put ssh key into .ssh

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

![](https://habrastorage.org/webt/gn/ux/xg/gnuxxggcfq2k8czx0mtpbzmvs7o.png)

### Access Grafana UI
```
$ kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Go to http://grafana.local (user: admin, password: result of first command).
Add new data source with type "Prometheus" and url "http://prometheus-server".
Import a new dashboard to Grafana (grafana.com dashboard: https://grafana.com/dashboards/1621, Prometheus: created one).

![](https://habrastorage.org/webt/xs/r4/wr/xsr4wrgueg7hqsi0paopmeqcdk8.png)

# Logging

## Deploy Loghouse
```
$ helm repo add loghouse https://flant.github.io/loghouse/charts/
$ helm install --namespace loghouse --create-namespace -f manifests/loghouse-values.yml \
  loghouse loghouse/loghouse
```
Go to http://loghouse.local (login: admin, password: PASSWORD).

![](https://habrastorage.org/webt/gn/lp/qs/gnlpqsq5pqmdzt_tudg1cgkbgzm.png)

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
  --bucket backup-backet-apatsev \
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
