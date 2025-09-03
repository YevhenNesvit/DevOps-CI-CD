# Kubernetes Deployment with Terraform, Helm, Jenkins та Argo CD

Цей проект демонструє інфраструктуру для розгортання Django застосунку в Amazon EKS (Elastic Kubernetes Service) з використанням **Terraform**, **Helm**, **Jenkins** та **Argo CD**.

## Архітектура

- **AWS VPC** – ізольована мережа з підмережами, маршрутизацією та Internet Gateway  
- **AWS EKS** – керований Kubernetes кластер  
- **AWS ECR** – зберігання Docker образів  
- **Terraform** – Infrastructure as Code  
- **Helm** – управління Kubernetes ресурсами  
- **Jenkins** – CI/CD сервер для автоматизації збірки та деплою  
- **Argo CD** – GitOps платформа для управління релізами у Kubernetes  
- **S3 + DynamoDB** – бекенд для Terraform state  

## Структура проекту

```
Progect/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf       # Виводи
│   │
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію
│   │
│   ├── eks/                      # Модуль для Kubernetes кластера
│   │   ├── eks.tf                # Створення кластера
│   │   ├── aws_ebs_csi_driver.tf # Встановлення плагіну csi driver
│   │   ├── variables.tf          # Змінні для EKS
│   │   └── outputs.tf            # Виведення інформації про кластер
│   │
│   ├── jenkins/             # Модуль для Helm-установки Jenkins
│   │   ├── jenkins.tf       # Helm release для Jenkins
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   ├── providers.tf     # Оголошення провайдерів
│   │   ├── values.yaml      # Конфігурація Jenkins
│   │   └── outputs.tf       # Виводи (URL, пароль адміністратора)
│   │ 
│   └── argo_cd/             # Модуль для Helm-установки Argo CD
│       ├── jenkins.tf       # Helm release для Argo CD
│       ├── variables.tf     # Змінні (версія чарта, namespace, repo URL тощо)
│       ├── providers.tf     # Kubernetes + Helm провайдери
│       ├── values.yaml      # Кастомна конфігурація Argo CD
│       ├── outputs.tf       # Виводи (hostname, initial admin password)
│       └── charts/          # Helm-чарт для створення app'ів
│           ├── Chart.yaml
│           ├── values.yaml  # Список applications, repositories
│           └── templates/
│               ├── application.yaml
│               └── repository.yaml
│
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     # ConfigMap зі змінними середовища
```

---

## Передумови

1. **AWS CLI** (налаштований профіль з доступами)  
2. **Terraform** >= 1.0  
3. **kubectl** >= 1.20  
4. **Helm** >= 3.0  
5. **Docker** (для збірки образів)  
6. Доступ до AWS (EKS, ECR, VPC, S3, DynamoDB)  

---

## Кроки використання

### 1. Ініціалізація Terraform

```bash
terraform init
terraform plan
terraform apply
```

> Будуть створені ресурси: VPC, EKS, ECR, Jenkins, Argo CD.

---

### 2. Перевірка Jenkins Job

Після застосування Terraform Jenkins встановиться у кластері через Helm.  

```bash
# Отримати пароль адміністратора
kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Отримати URL сервісу Jenkins
kubectl get svc jenkins -n jenkins
```

Далі:  
1. Залогінитися у Jenkins.  
2. Створити pipeline job для збірки Docker-образу Django.  
3. Налаштувати пуш у ECR (використати credentials з AWS IAM).  
4. Job після пушу може виконати `helm upgrade` для оновлення застосунку.  

---

### 3. Перегляд у Argo CD

Argo CD відповідає за **GitOps-деплой** додатків у кластер.  

```bash
# Отримати початковий пароль Argo CD admin
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode

# Отримати URL Argo CD
kubectl get svc argocd-server -n argocd
```

У веб-інтерфейсі Argo CD можна:  
- Побачити стан **django-app**  
- Перевірити синхронізацію з git-репозиторієм  
- Переконатися, що оновлення з Jenkins (новий образ у ECR) застосоване  

---

## CI/CD потік

1. **Terraform** створює інфраструктуру (VPC, EKS, Jenkins, Argo CD, ECR).  
2. **Jenkins** виконує pipeline: збирає Docker-образ, пушить у ECR.  
3. **Argo CD** підтягує Helm chart (django-app) і розгортає у кластері.  
4. **Користувач** отримує доступ до Django через LoadBalancer.  

---

## Очищення

```bash
helm uninstall jenkins -n jenkins
helm uninstall argocd -n argocd
terraform destroy
```

