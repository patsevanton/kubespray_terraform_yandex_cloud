# Установка Kubernetes кластера с помощью Kubespray в Yandex Cloud

Yandex.Cloud - облачная платформа, где каждый может создавать и совершенствовать свои цифровые сервисы, используя инфраструктуру и уникальные технологии Яндекса.

Kubespray — это набор Ansible ролей для установки и конфигурации системы оркестрации контейнерами Kubernetes.

Kubernetes (K8s) - это открытое программное обеспечение для автоматизации развёртывания, масштабирования и управления контейнеризированными приложениями.

## Регистрация на Yandex Cloud

https://cloud.yandex.ru/docs/billing/quickstart/

## Установка Yandex.Cloud (CLI) 
Интерфейс командной строки Yandex.Cloud (CLI) — скачиваемое программное обеспечение для управления вашими облачными ресурсами через командную строку.
```
$ curl https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
```

## Создание профиля Yandex Cloud

https://cloud.yandex.ru/docs/cli/quickstart

## Установка binenv
Binenv - утилита загрузки, установки и управления бинарными программами, которые вам нужны в повседневной жизни DevOps (например, kubectl, helm, ...).
https://github.com/devops-works/binenv

## Установка Terraform 
Terraform — это инструмент для создания декларативного кода, который позволяет разработчикам использовать язык высокого уровня, называемый HCL (HashiCorp Configuration Language) для описания нужной облачной или локальной инфраструктуры "конечного состояния" для запуска приложения. Затем он генерирует план для достижения этого конечного состояния и выполняет план по предоставлению инфраструктуры.
```
$ binenv install terraform
```

## Установка Kubectl
Kubectl — это инструмент командной строки для управления кластерами Kubernetes.
```
$ binenv install kubectl
```

## Установка Helm
Helm — это диспетчер пакетов для Kubernetes, упрощающий для разработчиков и операторов упаковку, настройку и развертывание приложений и служб в кластерах Kubernetes.
```
$ binenv install helm
```

## Установка jq
JQ - утилита для анализа, фильтрации, сравния и преобразовывания данных JSON.

```
$ sudo apt install jq
```

## Установка pip3 и git
```
$ sudo apt install python3-pip git
```

## Скачаем Kubespray версии 2.14.2 и установим зависимости для Kubespray 
```
$ wget https://github.com/kubernetes-sigs/kubespray/archive/refs/tags/v2.14.2.tar.gz
$ tar -xvzf v2.14.2.tar.gz
$ mv kubespray-2.14.2 kubespray
$ sudo pip3 install -r kubespray/requirements.txt
```

## Настроим Terraform переменные для доступа к Yandex Cloud
```
$ cp terraform/private.auto.tfvars.example terraform/private.auto.tfvars
$ yc config list
$ vim terraform/private.auto.tfvars
```

## Поместим ssh ключи в директорию .ssh

## Создание ресурсов в Yandex Cloud и установка Kubernetes кластера с помощью Kubespray
```
$ bash cluster_install.sh
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

![](https://habrastorage.org/webt/9i/e0/cg/9ie0cgb2f_dtufwygc_2geqcatk.png)

Ресурс "yandex_iam_service_account" находится в каталоге, где вы создаете инфраструктуру в разделе Сервисные аккаунты. 

![](https://habrastorage.org/webt/sv/bd/2b/svbd2bb0rt6mb8bchjc1s2e1eze.png)

Ресурс "yandex_compute_instance_group" находится в разделе Compute Cloud в разделе Группы виртуальных машин

![](https://habrastorage.org/webt/ao/tt/t-/aottt-hsr8s-roxabhjednimf7c.png)

Ресурс yandex_storage_bucket находится в разделе Object Storage

![](https://habrastorage.org/webt/gd/kd/ss/gdkdssznvixut8dr8wgftwjej4k.png)


## Копирование конфига kubernetes
```
$ mkdir -p ~/.kube && cp kubespray/inventory/mycluster/artifacts/admin.conf ~/.kube/config
```

## Разворачивание тестового приложения
```
$ kubectl apply -f manifests/test-app.yml
```

## Добавление в файл hosts информации о названии и IP адресах наших серверов
```
$ sudo sh -c "cat kubespray_inventory/etc-hosts >> /etc/hosts"
```

## Проверка внешнего доступа тестового приложения
```
$ curl hello.local
Hello from my-deployment-784598767c-7gjjs
```

# Мониторинг кластера Kubernetes

## Установка Kubernetes Dashboard
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

## Установка Prometheus и Grafana
```
$ helm install --namespace monitoring --create-namespace -f manifests/prometheus-values.yml \
  prometheus stable/prometheus
$ helm install --namespace monitoring --create-namespace -f manifests/grafana-values.yml \
  grafana stable/grafana
```

### Доступ к Prometheus UI

Go to http://prometheus.local

![](https://habrastorage.org/webt/gn/ux/xg/gnuxxggcfq2k8czx0mtpbzmvs7o.png)

### Доступ к Grafana UI
```
$ kubectl get secret -n monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Go to http://grafana.local (user: admin, password: result of first command).
Add new data source with type "Prometheus" and url "http://prometheus-server".
Import a new dashboard to Grafana (grafana.com dashboard: https://grafana.com/dashboards/1621, Prometheus: created one).

![](https://habrastorage.org/webt/xs/r4/wr/xsr4wrgueg7hqsi0paopmeqcdk8.png)

# Логирование

## Развертывание Loghouse
Loghouse — Open Source-система для работы с логами в Kubernetes
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

# Бекапирование/восстановление кластера kubernetes

## Установка Velero
Velero - это удобный инструмент резервного копирования для kubernetes, который сжимает и бэкапит объекты kubernetes в объектное хранилище.

https://velero.io/docs/v1.4/basic-install/

## Установка и конфигурирование AWS plugin для Velero
```
$ velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.1.0 \
  --bucket backup-backet-apatsev \
  --backup-location-config region=ru-central1-a,s3ForcePathStyle="true",s3Url=https://storage.yandexcloud.net \
  --snapshot-location-config region=ru-central1-a \
  --secret-file kubespray_inventory/credentials-velero
```

## Создание бекапа backup и просмотр его статуса
```
$ velero backup create my-first-backup
$ velero backup get
```

## Удаление тестового приложения
```
$ kubectl delete -f manifests/test-app.yml
```

## Восстановление бекапа и просмотр списка восстановленных бекапов
```
$ velero restore create --from-backup my-first-backup
$ velero restore get
```

# Удаление кластера kubernetes и ресурсов в Yandex Cloud

```
$ bash cluster_destroy.sh
```
