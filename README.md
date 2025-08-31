# Django Kubernetes Deployment with Terraform and Helm

Цей проект демонструє розгортання Django застосунку в Amazon EKS (Elastic Kubernetes Service) за допомогою Terraform та Helm.

## Архітектура

- **AWS EKS** - керований Kubernetes кластер
- **ECR** - зберігання Docker образів
- **VPC** - ізольована мережа з публічними та приватними підмережами
- **Terraform** - Infrastructure as Code
- **Helm** - управління Kubernetes ресурсами
- **HPA** - автоматичне масштабування подів

## Структура проекту

```
lesson-7/
├── main.tf                    # Головний Terraform файл
├── backend.tf                 # Налаштування backend
├── outputs.tf                 # Виводи Terraform
├── terraform.tfvars.example   # Приклад змінних
├── deploy.sh                  # Скрипт деплойменту
├── Dockerfile.example         # Приклад Dockerfile
├── requirements.txt.example   # Python залежності
│
├── modules/                   # Terraform модулі
│   ├── s3-backend/           # S3 + DynamoDB для стейту
│   ├── vpc/                  # VPC налаштування
│   ├── ecr/                  # ECR репозиторій
│   └── eks/                  # EKS кластер
│       ├── eks.tf
│       ├── variables.tf
│       └── outputs.tf
│
└── charts/                   # Helm charts
    └── django-app/
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
            ├── deployment.yaml
            ├── service.yaml
            ├── configmap.yaml
            ├── hpa.yaml
            └── _helpers.tpl
```

## Передумови

1. **AWS CLI** встановлений та налаштований
2. **Terraform** >= 1.0
3. **kubectl** встановлений
4. **Helm** >= 3.0
5. **Docker** встановлений
6. Права доступу до AWS для створення EKS, ECR, VPC ресурсів

## Інсталяція та запуск

### 1. Підготовка конфігурації

```bash
# Клонувати репозиторій
git clone <your-repo-url>
cd lesson-7
```

### 2. Ініціалізація Terraform

```bash
# Ініціалізація Terraform
terraform init

# Перевірити план
terraform plan

# Застосувати зміни
terraform apply
```

### 3. Підготовка Django застосунку

```bash
docker build -t django:latest ./django

# Перетегування для ECR
docker tag django:latest 752105083048.dkr.ecr.us-east-1.amazonaws.com/lesson-7-ecr:latest

# Пуш у ECR
docker push 752105083048.dkr.ecr.us-east-1.amazonaws.com/lesson-7-ecr:latest
```

## Конфігурація

### Terraform змінні (terraform.tfvars)

- `aws_region` - AWS регіон
- `s3_bucket_name` - унікальне ім'я S3 bucket для Terraform state
- `eks_cluster_name` - ім'я EKS кластера
- `ecr_repository_name` - ім'я ECR репозиторію
- `node_instance_types` - типи EC2 інстансів для worker nodes

### Helm values (charts/django-app/values.yaml)

- `image.repository` - ECR repository URL (встановлюється автоматично)
- `config` - змінні середовища для Django
- `resources` - лімити CPU/пам'яті
- `autoscaling` - налаштування HPA

## Компоненти

### 1. EKS Кластер
- Керований Kubernetes кластер
- Worker nodes у приватних підмережах
- Auto Scaling Groups для worker nodes

### 2. ECR (Elastic Container Registry)
- Приватний Docker registry
- Автоматична аутентифікація з EKS

### 3. VPC мережа
- Публічні підмережі для Load Balancer
- Приватні підмережі для worker nodes
- NAT Gateway для вихідного трафіку

### 4. Helm Chart компоненти

#### Deployment
- Запускає Django поди
- Підключає ConfigMap з змінними середовища
- Health checks (liveness/readiness probes)

#### Service
- LoadBalancer тип для зовнішнього доступу
- Маршрутизує трафік до подів

#### ConfigMap
- Зберігає змінні середовища Django
- DEBUG, SECRET_KEY, DATABASE_URL, тощо

#### HPA (Horizontal Pod Autoscaler)
- Автоматичне масштабування 2-6 подів
- Базується на CPU utilization (70%)

## Моніторинг та управління

### Перевірка стану кластера

```bash
# Перевірити ноди
kubectl get nodes

# Перевірити поди
kubectl get pods

# Перевірити сервіси
kubectl get services

# Перевірити HPA
kubectl get hpa
```

### Логи застосунку

```bash
# Перегляд логів
kubectl logs -l app.kubernetes.io/name=django-app

# Слідкувати за логами
kubectl logs -l app.kubernetes.io/name=django-app -f
```

### Оновлення застосунку

```bash
# Оновити образ і розгорнути
helm upgrade django-app ./charts/django-app \
  --set image.tag=new-version

# Або перезапустити деплоймент
kubectl rollout restart deployment/django-app
```

## Очищення ресурсів

```bash
# Видалити Helm release
helm uninstall django-app

# Видалити Terraform ресурси
terraform destroy
```

## Безпека

- Worker nodes у приватних підмережах
- Security groups обмежують доступ
- ECR repositories приватні
- IAM ролі з мінімальними правами

## Troubleshooting

### Поди не запускаються
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### LoadBalancer не отримує IP
```bash
kubectl describe service django-app
# Перевірити AWS Load Balancer Controller
```

### ECR аутентифікація
```bash
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account>.dkr.ecr.us-west-2.amazonaws.com
```

## Додаткові можливості

### Ingress з TLS (бонус)
Для налаштування Ingress з cert-manager:

1. Встановити cert-manager
2. Створити Ingress resource
3. Налаштувати DNS запис

## Корисні посилання

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)