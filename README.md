# AWS Infrastructure with Django App - Complete DevOps Solution

🚀 Повна інфраструктура для деплою Django додатку в AWS з використанням EKS, RDS, Jenkins та ArgoCD.

## 📋 Зміст

- [Архітектура проекту](#-архітектура-проекту)
- [Компоненти інфраструктури](#-компоненти-інфраструктури)  
- [Django додаток](#-django-додаток)
- [Helm чарти](#-helm-чарти)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Швидкий старт](#-швидкий-старт)
- [Конфігурація](#-конфігурація)
- [Моніторинг](#-моніторинг-та-логування)
- [Безпека](#-безпека)
- [Команди](#-корисні-команди)
- [Troubleshooting](#-troubleshooting)

## 🏗️ Архітектура проекту

```
Project/
│
├── main.tf                 # Головний файл для підключення модулів
├── backend.tf              # Налаштування бекенду для стейтів (S3 + DynamoDB)
├── outputs.tf              # Загальні виводи ресурсів
├── terraform.tfvars        # Змінні конфігурації
├── README.md               # Документація проекту
│
├── modules/                # Каталог з усіма модулями
│  ├── s3-backend/          # S3 бакет і DynamoDB для Terraform state
│  │  ├── s3.tf            # Створення S3-бакета
│  │  ├── dynamodb.tf      # Створення DynamoDB
│  │  ├── variables.tf     # Змінні для S3
│  │  └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│  │
│  ├── vpc/                 # VPC, підмережі, Internet Gateway
│  │  ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│  │  ├── routes.tf        # Налаштування маршрутизації
│  │  ├── variables.tf     # Змінні для VPC
│  │  └── outputs.tf       # Виводи VPC (ID, підмережі, тощо)
│  │
│  ├── ecr/                 # ECR репозиторій для Docker images
│  │  ├── ecr.tf           # Створення ECR репозиторію
│  │  ├── variables.tf     # Змінні для ECR
│  │  └── outputs.tf       # Виведення URL репозиторію
│  │
│  ├── eks/                 # EKS кластер з EBS CSI driver
│  │  ├── eks.tf           # Створення кластера
│  │  ├── aws_ebs_csi_driver.tf # Встановлення плагіну CSI driver
│  │  ├── variables.tf     # Змінні для EKS
│  │  └── outputs.tf       # Виведення інформації про кластер
│  │
│  ├── rds/                 # RDS і Aurora PostgreSQL кластер
│  │  ├── rds.tf           # Створення RDS бази даних  
│  │  ├── aurora.tf        # Створення aurora кластера бази даних  
│  │  ├── shared.tf        # Спільні ресурси (subnet group, security group)
│  │  ├── variables.tf     # Змінні (ресурси, креденшели, values)
│  │  └── outputs.tf       # Виводи (endpoint, порт, креденшели)
│  │
│  ├── jenkins/             # Jenkins через Helm
│  │  ├── jenkins.tf       # Helm release для Jenkins
│  │  ├── variables.tf     # Змінні (ресурси, креденшели, values)
│  │  ├── providers.tf     # Оголошення провайдерів
│  │  ├── values.yaml      # Конфігурація jenkins
│  │  └── outputs.tf       # Виводи (URL, пароль адміністратора)
│  │
│  └── argo_cd/             # ArgoCD через Helm + GitOps додатки
│    ├── argocd.tf         # Helm release для ArgoCD
│    ├── variables.tf      # Змінні (версія чарта, namespace, repo URL тощо)
│    ├── providers.tf      # Kubernetes+Helm провайдери
│    ├── values.yaml       # Кастомна конфігурація Argo CD
│    ├── outputs.tf        # Виводи (hostname, initial admin password)
│    └── charts/           # Helm-чарт для створення app'ів
│       ├── Chart.yaml
│       ├── values.yaml    # Список applications, repositories
│       └── templates/
│         ├── application.yaml
│         └── repository.yaml
│
├── charts/                 # Helm чарти для додатків
│  └── django-app/          # Helm чарт для Django додатку
│    ├── templates/
│    │  ├── deployment.yaml
│    │  ├── service.yaml
│    │  ├── configmap.yaml
│    │  └── hpa.yaml
│    ├── Chart.yaml
│    └── values.yaml       # ConfigMap зі змінними середовища
│
└── Django/                 # Django додаток
   ├── app/                 # Django код
   ├── Dockerfile           # Production Docker образ
   ├── Jenkinsfile          # CI/CD pipeline
   └── docker-compose.yaml  # Локальна розробка
```

## 🔧 Компоненти інфраструктури

### 1. **S3 Backend (`modules/s3-backend/`)**
Забезпечує централізоване зберігання Terraform state з блокуванням.

**Ключові ресурси:**
- S3 бакет з версіонуванням та шифруванням
- DynamoDB таблиця для state locking
- IAM політики для доступу

**Використання:**
```hcl
module "s3_backend" {
  source = "./modules/s3-backend"
  
  bucket_name = "myapp-terraform-state"
  environment = "prod"
}
```

### 2. **VPC (`modules/vpc/`)**
Створює повну мережеву інфраструктуру AWS.

**Ключові ресурси:**
- VPC з кастомним CIDR
- Публічні та приватні підмережі (Multi-AZ)
- Internet Gateway та NAT Gateways
- Route Tables та Security Groups

**Особливості:**
- Multi-AZ архітектура для високодоступності
- Автоматичне налаштування маршрутизації
- DNS підтримка та резолюція

### 3. **ECR (`modules/ecr/`)**
Приватний Docker registry для контейнерів.

**Ключові ресурси:**
- ECR репозиторій з lifecycle policies
- IAM ролі для push/pull операцій
- Автоматичне сканування на вразливості

**Features:**
- Image scanning на CVE
- Lifecycle policies для очищення старих образів
- Cross-region replication

### 4. **EKS (`modules/eks/`)**
Managed Kubernetes кластер з додатковими компонентами.

**Ключові ресурси:**
- EKS Control Plane
- Managed Node Groups з автоскейлінгом
- **EBS CSI Driver** для persistent storage
- OIDC Provider для IAM інтеграції
- Storage Classes (GP3, IO1)

**EBS CSI Driver особливості:**
- Підтримка динамічного provisioning
- Різні типи дисків (GP2, GP3, IO1, IO2)
- Шифрування EBS volume
- Snapshot та backup можливості

### 5. **RDS (`modules/rds/`)**
Гібридний модуль для RDS інстансів та Aurora кластерів.

**Підтримувані конфігурації:**
- **RDS PostgreSQL** для простих додатків
- **Aurora PostgreSQL** для високонавантажених систем
- **Aurora Serverless v2** для змінного навантаження

**Ключові особливості:**
- Автоматичне керування паролями (AWS Secrets Manager)
- Multi-AZ розгортання
- Автоматичні backup та point-in-time recovery
- Performance Insights та CloudWatch integration
- Custom Parameter Groups

**Приклад конфігурації:**
```hcl
module "rds" {
  source = "./modules/rds"

  # Aurora кластер для продакшену
  use_aurora           = true
  engine              = "aurora-postgresql"
  aurora_instances_count = 2
  
  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_security_groups = [module.eks.cluster_security_group_id]
}
```

### 6. **Jenkins (`modules/jenkins/`)**
Jenkins CI/CD платформа розгорнута через Helm.

**Ключові компоненти:**
- Jenkins Master з persistent storage
- Helm Chart з кастомними values
- Pre-configured plugins та tools
- Integration з AWS services

**Pre-installed Tools:**
- Docker
- kubectl
- Helm
- AWS CLI
- Trivy (security scanning)

### 7. **ArgoCD (`modules/argo_cd/`)**
GitOps платформа для continuous delivery.

**Ключові компоненти:**
- ArgoCD Server з Web UI
- Application Controller
- Repository Server
- Кастомний Helm chart для автоматичного створення applications

**GitOps Features:**
- Git як single source of truth
- Automatic sync з Git repositories
- Multi-environment deployments
- Rollback та історія deployments

### Технологічний стек:
- **Django 4.2** - Web framework
- **Django REST Framework** - API development
- **PostgreSQL** - Primary database
- **Redis** - Caching and Celery broker
- **Celery** - Asynchronous task processing
- **Gunicorn** - WSGI HTTP Server
- **WhiteNoise** - Static file serving
- **django-environ** - Environment variable management

### Production Features:
- Multi-stage Docker builds для оптимізації розміру
- Non-root container user для безпеки
- Health checks та readiness probes
- Structured logging у JSON форматі
- Security middleware та headers
- Static files optimization

### Локальна розробка:
```bash
cd Django/
docker-compose up -d
```

**Сервіси в docker-compose:**
- **web** - Django application
- **db** - PostgreSQL database  
- **redis** - Cache та message broker
- **celery** - Background task worker
- **celery-beat** - Periodic task scheduler
- **nginx** - Reverse proxy та static files

## 📦 Helm чарти

### Django App Chart (`charts/django-app/`)

**Templates:**
```
templates/
├── deployment.yaml         # Kubernetes Deployment
├── service.yaml           # ClusterIP Service
├── configmap.yaml         # Application configuration
└── hpa.yaml              # Horizontal Pod Autoscaler
```

**Ключові особливості:**
- **Rolling deployments** з zero downtime
- **Resource limits** та requests
- **Liveness та readiness probes**
- **Environment variables** через ConfigMaps
- **Secrets** для sensitive даних
- **HPA** для автоматичного масштабування

**Приклад values.yaml:**
```yaml
image:
  repository: your-ecr-url/django-app
  tag: latest
  pullPolicy: IfNotPresent

replicaCount: 2

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## 🔄 CI/CD Pipeline

### Jenkins Pipeline (`Django/Jenkinsfile`)

**Pipeline стадії:**
1. **Checkout** - Клонування коду з Git
2. **Build Docker Image** - Збірка з версіонуванням
3. **Run Tests** - Unit та integration тести  
4. **Security Scan** - Trivy сканування образу
5. **Push to ECR** - Публікація в ECR registry
6. **Deploy to EKS** - Helm upgrade/install
7. **Smoke Tests** - Перевірка після deployment

**Особливості pipeline:**
- Автоматичне версіонування (BUILD_NUMBER + Git commit)
- Security scanning з Trivy
- Multi-stage testing
- Automatic rollback при невдачі
- Slack/email notifications
- Parallel execution де можливо

### ArgoCD GitOps Workflow

**Процес deployment:**
```
Developer Push → Git Repository → ArgoCD Sync → Kubernetes Deployment
```

**ArgoCD Applications автоматично створюються для:**
- Django app (різні environments)
- Monitoring stack
- Ingress controllers
- Additional microservices

## 🚀 Швидкий старт

### 1. Встановлення інструментів

**Обов'язкові інструменти:**
```bash
# Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip && sudo ./aws/install

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Helm
curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar -xzO linux-amd64/helm > helm
chmod +x helm && sudo mv helm /usr/local/bin/

# Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh
```

### 2. Налаштування AWS

```bash
# Налаштування credentials
aws configure
# AWS Access Key ID: your-key
# AWS Secret Access Key: your-secret  
# Default region: us-west-2
# Default output format: json

# Перевірка підключення
aws sts get-caller-identity
```

### 3. Клонування та налаштування проекту

```bash
# Клонування репозиторію
git clone https://github.com/your-org/aws-django-infrastructure.git
cd aws-django-infrastructure

# Копіювання та редагування змінних
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

### 4. Деплой інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Створення S3 backend (якщо потрібно)
cd modules/s3-backend
terraform init && terraform apply
cd ../..

# Планування повного deployment
terraform plan

# Застосування змін (може зайняти 15-20 хвилин)
terraform apply

# Перевірка outputs
terraform output
```

### 5. Налаштування kubectl та Helm

```bash
# Оновлення kubeconfig
aws eks update-kubeconfig --region us-west-2 --name $(terraform output -raw cluster_name)

# Перевірка підключення
kubectl get nodes

# Додавання Helm repositories
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 6. Доступ до сервісів

```bash
# Jenkins (отримання паролю)
kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode

# Port forwarding для Jenkins
kubectl port-forward service/jenkins 8080:8080

# ArgoCD (отримання паролю)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forwarding для ArgoCD  
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Helm Values для Django App

**Production values:**
```yaml
# charts/django-app/values.yaml
replicaCount: 3

image:
  repository: 123456789012.dkr.ecr.us-east-1.amazonaws.com/django-app
  tag: "latest"
  pullPolicy: Always

service:
  type: ClusterIP
  port: 80
  targetPort: 8000

ingress:
  enabled: true
  className: alb
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  hosts:
    - host: api.yourdomain.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 500m
    memory: 512Mi

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# Database connection
database:
  host: "your-aurora-endpoint"
  name: "django_db"
  user: "dbadmin"
  # password from secret

# Redis connection  
redis:
  host: "your-redis-endpoint"
  port: 6379
```

## 📊 Моніторинг та логування

### AWS CloudWatch Integration

**EKS Cluster Monitoring:**
```bash
# Встановлення CloudWatch Container Insights
kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cloudwatch-namespace.yaml

kubectl apply -f https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/cwagent/cwagent-daemonset.yaml
```

**Custom Metrics Dashboard:**
- EKS cluster health
- Node utilization  
- Pod performance
- Application metrics
- Database performance

### Application Monitoring

**Endpoints:**
- `/api/health/` - Health check
- `/api/metrics/` - Application metrics
- `/api/status/` - Detailed status

### Logging Strategy

**Structured Logging Configuration:**
```python
# settings.py
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'json': {
            'format': '{"time": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "message": "%(message)s"}',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'json',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'INFO',
    },
}
```

**Log Aggregation:**
- **CloudWatch Logs** - Централізовані логи
- **Fluent Bit** - Log shipping
- **ElasticSearch + Kibana** (опційно)

## 🔒 Безпека

### Infrastructure Security

**Network Security:**
```hcl
# VPC з приватними підмережами
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Security Groups з мінімальними правилами
eks_additional_security_group_ids = [module.vpc.database_security_group_id]
```

**IAM Security:**
- Principle of least privilege
- Service-specific IAM roles
- OIDC integration для pod-level permissions
- AWS Secrets Manager для credentials

**Data Security:**
- EBS encryption at rest
- RDS encryption
- S3 bucket encryption
- SSL/TLS in transit

### Application Security

**Container Security:**
- Non-root user в Dockerfile
- Minimal base images (distroless)
- Security scanning з Trivy
- Image vulnerability management
- Read-only filesystem де можливо

### Security Scanning

**Pipeline Security Checks:**
```groovy
stage('Security Scan') {
    steps {
        script {
            // Container scanning
            sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}"
            
            // SAST scanning
            sh "semgrep --config=auto Django/"
            
            // Dependency scanning  
            sh "safety check -r Django/requirements.txt"
        }
    }
}
```

## 🛠️ Корисні команди

### Terraform Operations

```bash
# === BASIC OPERATIONS ===
terraform init              # Ініціалізація
terraform plan              # Планування змін
terraform apply             # Застосування змін  
terraform destroy           # Знищення інфраструктури

# === STATE MANAGEMENT ===
terraform show              # Показати поточний стан
terraform state list        # Список ресурсів у стейті
terraform state show aws_eks_cluster.main  # Деталі конкретного ресурсу

# === ADVANCED ===
terraform fmt -recursive    # Форматування коду
terraform validate          # Валідація синтаксису
terraform graph | dot -Tsvg > graph.svg  # Візуалізація залежностей

# === OUTPUT MANAGEMENT ===
terraform output            # Всі outputs
terraform output -raw cluster_endpoint  # Конкретний output
```

### Kubernetes Operations

```bash
# === CLUSTER INFO ===
kubectl cluster-info        # Інформація про кластер
kubectl get nodes -o wide   # Список нодів з деталями
kubectl top nodes           # Використання ресурсів нодами

# === WORKLOAD MANAGEMENT ===
kubectl get pods -A         # Всі поди в усіх namespace
kubectl get deployments -A  # Всі deployment'и
kubectl get services -A     # Всі сервіси

# === SPECIFIC APP OPERATIONS ===
kubectl logs -f deployment/django-app  # Логи Django додатку
kubectl exec -it deployment/django-app -- python manage.py shell  # Django shell

# === SCALING ===
kubectl scale deployment django-app --replicas=5  # Масштабування
kubectl autoscale deployment django-app --cpu-percent=50 --min=1 --max=10  # HPA

# === DEBUGGING ===
kubectl describe pod <pod-name>     # Деталі поду
kubectl get events --sort-by=.metadata.creationTimestamp  # Події

# === PORT FORWARDING ===
kubectl port-forward service/django-app 8000:80    # Django app
kubectl port-forward service/jenkins 8080:8080     # Jenkins
kubectl port-forward svc/argocd-server -n argocd 8080:443  # ArgoCD
```

### Docker Operations

```bash
# === BUILD & RUN ===
cd Django/
docker build -t django-app:latest .           # Збірка образу
docker run -p 8000:8000 django-app:latest     # Запуск контейнера

# === ECR OPERATIONS ===
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-west-2.amazonaws.com

docker tag django-app:latest 123456789012.dkr.ecr.us-west-2.amazonaws.com/django-app:latest
docker push 123456789012.dkr.ecr.us-west-2.amazonaws.com/django-app:latest

# === LOCAL DEVELOPMENT ===
docker-compose up -d              # Запуск всього стеку
docker-compose logs -f web        # Логи Django
docker-compose exec web python manage.py migrate  # Запуск міграцій
docker-compose down               # Зупинка стеку

# === CLEANUP ===
docker system prune -a            # Очищення всіх unused образів
docker volume prune               # Очищення volumes
```

### Helm Operations

```bash
# === REPOSITORY MANAGEMENT ===
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# === DEPLOYMENT OPERATIONS ===
helm install django-app ./charts/django-app              # Встановлення
helm upgrade django-app ./charts/django-app              # Оновлення
helm uninstall django-app                               # Видалення

# === DEBUGGING ===
helm template django-app ./charts/django-app            # Рендерінг templates
helm get values django-app                              # Поточні values
helm history django-app                                 # Історія релізів
helm rollback django-app 1                             # Rollback до версії

# === CHART DEVELOPMENT ===
helm lint ./charts/django-app                          # Перевірка chart'у
helm package ./charts/django-app                       # Створення .tgz
```

### Django Operations

```bash
# === LOCAL DEVELOPMENT ===
cd Django/app/
python manage.py runserver 0.0.0.0:8000    # Запуск dev server
python manage.py migrate                    # Застосування міграцій
python manage.py makemigrations            # Створення міграцій
python manage.py createsuperuser           # Створення admin користувача
python manage.py collectstatic             # Збір статичних файлів

# === DATABASE OPERATIONS ===
python manage.py dbshell                   # Підключення до БД
python manage.py dumpdata > backup.json    # Backup даних
python manage.py loaddata backup.json      # Відновлення даних

# === CELERY OPERATIONS ===
celery -A myproject worker -l info         # Запуск worker'а
celery -A myproject beat -l info           # Запуск scheduler'а
celery -A myproject flower                 # Моніторинг UI

# === IN KUBERNETES ===
kubectl exec -it deployment/django-app -- python manage.py migrate
kubectl exec -it deployment/django-app -- python manage.py shell
```

### AWS CLI Operations

```bash
# === EKS OPERATIONS ===
aws eks list-clusters                                    # Список кластерів
aws eks describe-cluster --name myapp-eks               # Деталі кластера
aws eks update-kubeconfig --name myapp-eks              # Оновлення kubeconfig

# === RDS OPERATIONS ===
aws rds describe-db-instances                           # Список RDS
aws rds describe-db-clusters                            # Список Aurora
aws rds create-db-snapshot --db-instance-identifier mydb --db-snapshot-identifier mydb-snapshot

# === ECR OPERATIONS ===
aws ecr describe-repositories                           # Список репозиторіїв
aws ecr list-images --repository-name django-app       # Список образів
aws ecr batch-delete-image --repository-name django-app --image-ids imageTag=old-tag

# === SECRETS MANAGER ===
aws secretsmanager list-secrets                         # Список секретів
aws secretsmanager get-secret-value --secret-id prod/db/password --query SecretString --output text
```

## 🔍 Troubleshooting

### EKS Issues

**Pod не запускається:**
```bash
# Діагностика
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --field-selector involvedObject.name=<pod-name>

# Перевірка node resources
kubectl top nodes
kubectl describe node <node-name>

# Перевірка EBS CSI Driver
kubectl get pods -n kube-system | grep ebs-csi
kubectl logs -n kube-system deployment/ebs-csi-controller
```

**Storage Issues:**
```bash
# Перевірка storage classes
kubectl get storageclass

# Перевірка PVC
kubectl get pvc
kubectl describe pvc <pvc-name>

# Перевірка EBS volumes
aws ec2 describe-volumes --filters "Name=tag:kubernetes.io/cluster/myapp-eks,Values=owned"
```

**Networking Issues:**
```bash
# Перевірка DNS
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup kubernetes.default

# Перевірка connectivity
kubectl run -it --rm debug --image=nicolaka/netshoot --restart=Never
```

### Database Issues

**Connection Problems:**
```bash
# Перевірка RDS статусу
aws rds describe-db-instances --db-instance-identifier myapp-db

# Тест підключення з pod'а
kubectl run -it --rm psql --image=postgres:15 --restart=Never -- psql -h your-db-endpoint -U dbuser -d dbname

# Перевірка security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

**Performance Issues:**
```bash
# CloudWatch metrics
aws logs filter-log-events --log-group-name /aws/rds/instance/myapp-db/postgresql

# Performance Insights
aws pi get-resource-metrics --service-type RDS --identifier db-ABCDEFGHIJKLMNOP01234567890123456
```

### Application Issues

**Django Debugging:**
```bash
# Логи application
kubectl logs -f deployment/django-app
kubectl logs -f deployment/django-app --previous  # Previous container

# Django shell в Kubernetes
kubectl exec -it deployment/django-app -- python manage.py shell

# Database connectivity test
kubectl exec -it deployment/django-app -- python manage.py dbshell
```

**Performance Problems:**
```bash
# Resource utilization
kubectl top pods
kubectl describe hpa django-app

# Memory issues
kubectl exec -it deployment/django-app -- ps aux
kubectl exec -it deployment/django-app -- free -h
```

### Jenkins Issues

**Pipeline Failures:**
```bash
# Jenkins logs
kubectl logs -f deployment/jenkins

# Plugin issues
kubectl exec -it deployment/jenkins -- cat /var/jenkins_home/logs/wrapper.log

# Reset Jenkins admin password
kubectl get secret jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```

**Build Agent Problems:**
```bash
# Check available executors
# Go to Jenkins UI -> Manage Jenkins -> Nodes

# Pod Template issues (if using Kubernetes plugin)
kubectl get pods -l jenkins=slave
kubectl describe pod <build-pod-name>
```

### ArgoCD Issues

**Sync Problems:**
```bash
# ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller
kubectl logs -n argocd deployment/argocd-server

# Application status
kubectl get applications -n argocd
kubectl describe application django-app -n argocd

# Manual sync
argocd app sync django-app
```

**Git Repository Access:**
```bash
# Check repository connection
argocd repo list
argocd repo add https://github.com/your-org/your-repo.git --username your-user --password your-token

# Certificate issues
kubectl get configmap argocd-tls-certs-cm -n argocd -o yaml
```

## 🚨 Emergency Procedures

### Database Recovery

**RDS Point-in-time Recovery:**
```bash
# Restore RDS to specific time
aws rds restore-db-instance-to-point-in-time \
    --source-db-instance-identifier myapp-db \
    --target-db-instance-identifier myapp-db-restored \
    --restore-time 2024-01-15T10:30:00.000Z
```

**Aurora Cluster Recovery:**
```bash
# Restore Aurora cluster
aws rds restore-db-cluster-to-point-in-time \
    --source-db-cluster-identifier myapp-aurora \
    --db-cluster-identifier myapp-aurora-restored \
    --restore-time 2024-01-15T10:30:00.000Z
```

### Application Rollback

**Helm Rollback:**
```bash
# Check release history
helm history django-app

# Rollback to previous version
helm rollback django-app 1

# Or rollback to specific revision
helm rollback django-app 2
```

**ArgoCD Rollback:**
```bash
# Rollback through ArgoCD
argocd app rollback django-app

# Or rollback to specific revision
argocd app rollback django-app --revision HEAD~1
```

### Infrastructure Recovery

**EKS Node Group Issues:**
```bash
# Scale node group to 0 and back
aws eks update-nodegroup-config \
    --cluster-name myapp-eks \
    --nodegroup-name main-nodes \
    --scaling-config minSize=0,maxSize=5,desiredSize=0

# Wait and scale back up
aws eks update-nodegroup-config \
    --cluster-name myapp-eks \
    --nodegroup-name main-nodes \
    --scaling-config minSize=1,maxSize=5,desiredSize=2
```