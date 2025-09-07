# RDS Module

Універсальний Terraform модуль для створення AWS RDS інстансів або Aurora кластерів з автоматичним налаштуванням всіх необхідних ресурсів.

## Особливості

- **Гібридна підтримка**: Створення як звичайних RDS інстансів, так і Aurora кластерів
- **Автоматичне налаштування**: Створює DB Subnet Group, Security Group, Parameter Groups
- **Гнучкість**: Підтримує різні типи БД, версії та конфігурації
- **Безпека**: Автоматичне шифрування, керування паролями через AWS Secrets Manager
- **Моніторинг**: Інтеграція з CloudWatch та Performance Insights

## Швидкий старт

### RDS Instance (PostgreSQL)

```hcl
module "rds" {
  source = "./modules/rds"

  # Базова конфігурація
  use_aurora = false
  engine     = "postgres"
  
  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_security_groups = [module.eks.cluster_security_group_id]
  
  # Теги
  environment = "dev"
  project     = "myapp"
}
```

### Aurora Cluster (PostgreSQL)

```hcl
module "aurora" {
  source = "./modules/rds"

  # Aurora конфігурація
  use_aurora           = true
  engine              = "aurora-postgresql"
  aurora_instances_count = 2

  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_cidr_blocks = ["10.0.0.0/16"]
  
  # Високонавантаженість
  instance_class = "db.r6g.large"
  
  # Теги
  environment = "prod"
  project     = "myapp"
}
```

## Детальні приклади використання

### Повна конфігурація RDS

```hcl
module "rds_full" {
  source = "./modules/rds"

  # === ОСНОВНА КОНФІГУРАЦІЯ ===
  use_aurora     = false
  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.t3.small"

  # === БАЗА ДАНИХ ===
  db_name  = "appdb"
  username = "dbadmin"
  # password буде автоматично згенерований та збережений в Secrets Manager
  manage_master_user_password = true

  # === МЕРЕЖА ===
  vpc_id                     = "vpc-12345678"
  subnet_ids                = ["subnet-12345", "subnet-67890"]
  allowed_cidr_blocks       = ["10.0.0.0/16"]
  allowed_security_groups   = ["sg-eks-nodes"]
  publicly_accessible       = false

  # === СХОВИЩЕ ===
  allocated_storage      = 100
  max_allocated_storage  = 1000
  storage_type          = "gp3"
  storage_encrypted     = true

  # === ВИСОКОНАВАНТАЖЕНІСТЬ ===
  multi_az            = true
  deletion_protection = true

  # === РЕЗЕРВНІ КОПІЇ ===
  backup_retention_period = 14
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  skip_final_snapshot    = false

  # === МОНІТОРИНГ ===
  monitoring_interval                   = 60
  performance_insights_enabled         = true
  performance_insights_retention_period = 7
  enabled_cloudwatch_logs_exports      = ["postgresql"]

  # === ПАРАМЕТРИ БД ===
  custom_db_parameters = {
    max_connections           = "200"
    work_mem                 = "8MB"
    shared_buffers          = "256MB"
    effective_cache_size    = "1GB"
  }

  # === ТЕГИ ===
  environment = "prod"
  project     = "myapp"
  tags = {
    Owner       = "DevOps Team"
    CostCenter  = "Engineering"
    Backup      = "Required"
  }
}
```

### Aurora з Serverless v2

```hcl
module "aurora_serverless" {
  source = "./modules/rds"

  # Aurora Serverless v2
  use_aurora     = true
  engine         = "aurora-postgresql"
  engine_version = "15.4"
  
  # Serverless конфігурація
  aurora_serverless_v2_scaling = {
    min_capacity = 0.5
    max_capacity = 16
  }
  
  # Одна інстанція для старту
  aurora_instances_count = 1

  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  
  # Безпека
  allowed_security_groups = [module.app.security_group_id]

  # Теги
  environment = "staging"
  project     = "myapp"
}
```

### Розробницька конфігурація

```hcl
module "rds_dev" {
  source = "./modules/rds"

  # Мінімальна конфігурація для розробки
  use_aurora     = false
  engine         = "postgres"
  instance_class = "db.t3.micro"

  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids
  allowed_cidr_blocks = ["10.0.0.0/8"]

  # Розробницькі налаштування
  multi_az                = false
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot    = true

  # Теги
  environment = "dev"
  project     = "myapp"
  
  tags = {
    AutoShutdown = "true"
    Environment  = "development"
  }
}
```

## Змінні модуля

### Основна конфігурація

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `use_aurora` | `bool` | `false` | Використовувати Aurora кластер замість RDS інстансу |
| `engine` | `string` | `"postgres"` | Тип БД: `postgres` або `aurora-postgresql` |
| `engine_version` | `string` | `"15.4"` | Версія БД |
| `instance_class` | `string` | `"db.t3.micro"` | Клас інстансу БД |
| `identifier_prefix` | `string` | `"app"` | Префікс для ідентифікаторів ресурсів |

### Конфігурація бази даних

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `db_name` | `string` | `"appdb"` | Ім'я бази даних |
| `username` | `string` | `"dbadmin"` | Користувач-адміністратор |
| `password` | `string` | `null` | Пароль (якщо null - генерується автоматично) |
| `manage_master_user_password` | `bool` | `true` | Керувати паролем через AWS Secrets Manager |
| `port` | `number` | `null` | Порт БД (за замовчуванням 5432 для PostgreSQL) |

### Сховище (тільки для RDS)

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `allocated_storage` | `number` | `20` | Початковий розмір сховища (ГБ) |
| `max_allocated_storage` | `number` | `100` | Максимальний розмір для автомасштабування |
| `storage_type` | `string` | `"gp3"` | Тип сховища: `gp2`, `gp3`, `io1`, `io2` |
| `storage_encrypted` | `bool` | `true` | Шифрування сховища |
| `kms_key_id` | `string` | `null` | KMS ключ для шифрування |

### Мережа

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `vpc_id` | `string` | - | ID VPC (обов'язково) |
| `subnet_ids` | `list(string)` | - | ID підмереж для DB Subnet Group (обов'язково) |
| `allowed_cidr_blocks` | `list(string)` | `[]` | CIDR блоки з доступом до БД |
| `allowed_security_groups` | `list(string)` | `[]` | Security Groups з доступом до БД |
| `publicly_accessible` | `bool` | `false` | Публічний доступ до БД |

### Високонавантаженість

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `multi_az` | `bool` | `false` | Multi-AZ розгортання (тільки RDS) |
| `backup_retention_period` | `number` | `7` | Період зберігання резервних копій (дні) |
| `backup_window` | `string` | `"03:00-04:00"` | Вікно створення резервних копій |
| `maintenance_window` | `string` | `"sun:04:00-sun:05:00"` | Вікно обслуговування |
| `deletion_protection` | `bool` | `true` | Захист від видалення |
| `skip_final_snapshot` | `bool` | `false` | Пропустити фінальний знімок |

### Aurora специфічні налаштування

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `aurora_instances_count` | `number` | `1` | Кількість Aurora інстансів |
| `aurora_serverless_v2_scaling` | `object` | `null` | Конфігурація Serverless v2 |
| `aurora_global_cluster_identifier` | `string` | `null` | ID глобального кластера |

### Моніторинг

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `monitoring_interval` | `number` | `60` | Інтервал розширеного моніторингу (секунди) |
| `monitoring_role_arn` | `string` | `null` | IAM роль для моніторингу |
| `performance_insights_enabled` | `bool` | `true` | Увімкнути Performance Insights |
| `performance_insights_retention_period` | `number` | `7` | Період зберігання Performance Insights (дні) |
| `enabled_cloudwatch_logs_exports` | `list(string)` | `[]` | Типи логів для експорту в CloudWatch |

### Параметри БД

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `custom_db_parameters` | `map(string)` | `{}` | Кастомні параметри БД |

### Теги

| Змінна | Тип | За замовчуванням | Опис |
|--------|-----|------------------|------|
| `environment` | `string` | `"dev"` | Назва середовища |
| `project` | `string` | `"myapp"` | Назва проекту |
| `tags` | `map(string)` | `{}` | Додаткові теги |

## Виходи модуля

### Підключення

| Вихід | Опис |
|-------|------|
| `endpoint` | Адреса для підключення до БД |
| `reader_endpoint` | Адреса для читання (тільки Aurora) |
| `port` | Порт БД |
| `connection_string` | Рядок підключення (без пароля) |
| `database_name` | Ім'я бази даних |
| `username` | Користувач БД |

### Ідентифікатори ресурсів

| Вихід | Опис |
|-------|------|
| `identifier` | ID БД або кластера |
| `arn` | ARN БД або кластера |
| `instance_identifiers` | ID Aurora інстансів |
| `security_group_id` | ID Security Group |
| `subnet_group_name` | Ім'я DB Subnet Group |

### Secrets Manager

| Вихід | Опис |
|-------|------|
| `master_user_secret_arn` | ARN секрету з паролем в Secrets Manager |

## Як змінити тип БД

### PostgreSQL на Aurora PostgreSQL

```hcl
# Було
module "rds" {
  source = "./modules/rds"
  
  use_aurora = false
  engine     = "postgres"
  # ...
}

# Стало
module "aurora" {
  source = "./modules/rds"
  
  use_aurora = true
  engine     = "aurora-postgresql"  # Обов'язково змінити!
  # ...
}
```

### Зміна версії

```hcl
module "rds" {
  source = "./modules/rds"
  
  engine         = "postgres"
  engine_version = "16.1"  # Оновити версію
  # ...
}
```

### Зміна класу інстансу

```hcl
# Для розробки
instance_class = "db.t3.micro"

# Для тестування
instance_class = "db.t3.small"

# Для продакшену
instance_class = "db.r6g.large"

# Для Aurora - можна використовувати інші класи
instance_class = "db.r6g.xlarge"
```

### Підтримувані класи інстансів

#### RDS PostgreSQL
- **Загального призначення**: `db.t3.*`, `db.m6i.*`, `db.m5.*`
- **Оптимізовані для пам'яті**: `db.r6g.*`, `db.r5.*`, `db.x1e.*`
- **Потужні обчислення**: `db.c6i.*`, `db.c5.*`

#### Aurora PostgreSQL
- **Загального призначення**: `db.t4g.*`, `db.t3.*`
- **Оптимізовані для пам'яті**: `db.r6g.*`, `db.r5.*`
- **Serverless v2**: Автоматичне масштабування

## Налаштування параметрів БД

### PostgreSQL параметри за замовчуванням

```hcl
# Автоматично встановлюються такі параметри:
default_postgres_params = {
  max_connections                = "100"
  log_statement                 = "all"
  work_mem                      = "4MB"
  shared_preload_libraries      = "pg_stat_statements"
  log_min_duration_statement    = "1000"
  log_checkpoints              = "on"
  log_lock_waits               = "on"
}
```

### Кастомні параметри

```hcl
module "rds" {
  source = "./modules/rds"
  
  # Перевизначити або додати параметри
  custom_db_parameters = {
    max_connections      = "200"
    work_mem            = "8MB"
    shared_buffers      = "256MB"
    effective_cache_size = "1GB"
    
    # Параметри для продуктивності
    random_page_cost     = "1.1"
    seq_page_cost       = "1"
    
    # Параметри для логування
    log_statement       = "mod"
    log_duration        = "on"
  }
}
```

## Безпека

### Керування паролями

```hcl
# Рекомендований спосіб - AWS Secrets Manager
manage_master_user_password = true

# Або власний пароль
password = "your-secure-password"
manage_master_user_password = false
```

### Налаштування доступу

```hcl
# Доступ з конкретних мереж
allowed_cidr_blocks = [
  "10.0.0.0/16",    # VPC CIDR
  "172.16.0.0/12"   # Додаткові мережі
]

# Доступ з конкретних Security Groups
allowed_security_groups = [
  "sg-app-servers",
  "sg-bastion",
  "sg-monitoring"
]
```

## Моніторинг та логування

```hcl
module "rds" {
  source = "./modules/rds"
  
  # Performance Insights
  performance_insights_enabled         = true
  performance_insights_retention_period = 7  # або 31 днів
  
  # CloudWatch логи
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  # Розширений моніторинг
  monitoring_interval = 60  # 60 секунд
  
  # Параметри для детального логування
  custom_db_parameters = {
    log_statement              = "all"
    log_min_duration_statement = "1000"
    log_checkpoints           = "on"
    log_connections           = "on"
    log_disconnections        = "on"
  }
}
```

## Приклади для різних середовищ

### Розробка (Development)

```hcl
module "rds_dev" {
  source = "./modules/rds"

  use_aurora     = false
  instance_class = "db.t3.micro"
  
  # Мінімальні налаштування
  allocated_storage       = 20
  backup_retention_period = 1
  multi_az               = false
  deletion_protection    = false
  skip_final_snapshot   = true
  
  environment = "dev"
}
```

### Тестування (Staging)

```hcl
module "rds_staging" {
  source = "./modules/rds"

  use_aurora     = false
  instance_class = "db.t3.small"
  
  # Середні налаштування
  allocated_storage       = 100
  backup_retention_period = 7
  multi_az               = false
  deletion_protection    = true
  
  environment = "staging"
}
```

### Продукція (Production)

```hcl
module "aurora_prod" {
  source = "./modules/rds"

  use_aurora           = true
  engine              = "aurora-postgresql"
  instance_class      = "db.r6g.large"
  aurora_instances_count = 2
  
  # Продукційні налаштування
  backup_retention_period = 30
  deletion_protection    = true
  storage_encrypted     = true
  
  # Моніторинг
  performance_insights_enabled         = true
  performance_insights_retention_period = 31
  monitoring_interval                   = 60
  
  environment = "prod"
}
```

## Troubleshooting

### Часті помилки

1. **Неправильний engine для Aurora**
   ```hcl
   # ❌ Неправильно
   use_aurora = true
   engine     = "postgres"
   
   # ✅ Правильно
   use_aurora = true
   engine     = "aurora-postgresql"
   ```

2. **Відсутні підмережі в різних AZ**
   ```hcl
   # ✅ Підмережі повинні бути в різних зонах доступності
   subnet_ids = [
     "subnet-12345",  # us-west-2a
     "subnet-67890"   # us-west-2b
   ]
   ```

3. **Неправильний клас для Aurora Serverless v2**
   ```hcl
   # ✅ Для Serverless v2 використовуйте сумісні класи
   aurora_serverless_v2_scaling = {
     min_capacity = 0.5
     max_capacity = 16
   }
   ```

### Перевірка стану ресурсів

```bash
# Перевірити статус БД
terraform output

# Отримати connection string
terraform output connection_string

# Перевірити секрет в Secrets Manager
aws secretsmanager get-secret-value --secret-id $(terraform output -raw master_user_secret_arn)
```

## Підтримка

Для питань та проблем створіть issue в репозиторії проекту.

## Ліцензія

MIT License