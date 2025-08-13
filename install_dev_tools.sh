#!/bin/bash

set -e

# Кольори для виводу
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функції для виводу повідомлень
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функція для перевірки, чи команда існує
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Перевірка чи система Ubuntu/Debian
check_system() {
    if ! command_exists apt-get; then
        log_error "Цей скрипт призначений тільки для Ubuntu/Debian систем!"
        log_error "apt-get не знайдено в системі."
        exit 1
    fi
    
    log_info "Система підтримується. Продовжуємо встановлення..."
}

# Функція для оновлення пакетів
update_packages() {
    log_info "Оновлення списку пакетів..."
    sudo apt-get update -y
}

# Функція для встановлення Docker
install_docker() {
    if command_exists docker; then
        log_success "Docker вже встановлено. Версія: $(docker --version)"
        return 0
    fi

    log_info "Встановлення Docker..."
    
    # Встановлення залежностей
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Додавання офіційного GPG ключа Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Додавання репозиторію Docker
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Оновлення та встановлення Docker
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Запуск Docker сервісу
    sudo systemctl start docker
    sudo systemctl enable docker

    # Додавання користувача до групи docker
    sudo usermod -aG docker $USER

    log_success "Docker встановлено успішно!"
    log_warning "Перезайдіть в систему або виконайте 'newgrp docker' для застосування групових прав."
}

# Функція для встановлення Docker Compose
install_docker_compose() {
    # Перевірка Docker Compose плагіна (новий підхід)
    if docker compose version >/dev/null 2>&1; then
        log_success "Docker Compose (плагін) вже встановлено. Версія: $(docker compose version --short)"
        return 0
    fi
    
    # Перевірка standalone версії
    if command_exists docker-compose; then
        log_success "Docker Compose вже встановлено. Версія: $(docker-compose --version)"
        return 0
    fi

    log_info "Встановлення Docker Compose..."
    
    # Docker Compose плагін встановлюється разом з Docker CE
    # Якщо з якихось причин плагін недоступний, встановлюємо standalone версію
    if ! docker compose version >/dev/null 2>&1; then
        log_info "Встановлення standalone версії Docker Compose..."
        
        DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
        
        sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        
        sudo chmod +x /usr/local/bin/docker-compose
    fi
    
    log_success "Docker Compose встановлено успішно!"
}

# Функція для встановлення Python
install_python() {
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
        PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
        PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
        
        if [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -ge 9 ]; then
            log_success "Python вже встановлено. Версія: $PYTHON_VERSION"
            return 0
        else
            log_warning "Знайдено Python $PYTHON_VERSION, але потрібна версія 3.9 або новіша."
        fi
    fi

    log_info "Встановлення Python 3.9+..."
    
    # Встановлення Python та необхідних пакетів
    sudo apt-get install -y python3 python3-pip python3-venv python3-dev

    log_success "Python встановлено успішно!"
}

# Функція для встановлення pip (якщо не встановлено)
install_pip() {
    if command_exists pip3 || command_exists pip; then
        log_success "pip вже встановлено."
        return 0
    fi

    log_info "Встановлення pip..."
    sudo apt-get install -y python3-pip
    
    log_success "pip встановлено успішно!"
}

# Функція для встановлення Django
install_django() {
    log_info "Перевірка наявності Django..."
    
    if python3 -c "import django; print('Django', django.get_version())" 2>/dev/null; then
        log_success "Django вже встановлено. Версія: $(python3 -c "import django; print(django.get_version())")"
        return 0
    fi

    log_info "Встановлення Django..."
    
    # Оновлення pip
    python3 -m pip install --upgrade pip --user
    
    # Встановлення Django
    python3 -m pip install django --user
    
    log_success "Django встановлено успішно!"
}

# Функція для перевірки встановлення
verify_installation() {
    log_info "Перевірка встановлених інструментів..."
    
    echo "==================== СТАТУС ВСТАНОВЛЕННЯ ===================="
    
    # Перевірка Docker
    if command_exists docker; then
        echo -e "✅ Docker: $(docker --version)"
    else
        echo -e "❌ Docker: не встановлено"
    fi
    
    # Перевірка Docker Compose
    if docker compose version >/dev/null 2>&1; then
        echo -e "✅ Docker Compose: $(docker compose version --short)"
    elif command_exists docker-compose; then
        echo -e "✅ Docker Compose: $(docker-compose --version)"
    else
        echo -e "❌ Docker Compose: не встановлено"
    fi
    
    # Перевірка Python
    if command_exists python3; then
        echo -e "✅ Python: $(python3 --version)"
    else
        echo -e "❌ Python: не встановлено"
    fi
    
    # Перевірка pip
    if command_exists pip3; then
        echo -e "✅ pip: $(pip3 --version | cut -d' ' -f1,2)"
    elif command_exists pip; then
        echo -e "✅ pip: $(pip --version | cut -d' ' -f1,2)"
    else
        echo -e "❌ pip: не встановлено"
    fi
    
    # Перевірка Django
    if python3 -c "import django" 2>/dev/null; then
        echo -e "✅ Django: $(python3 -c "import django; print(django.get_version())")"
    else
        echo -e "❌ Django: не встановлено"
    fi
    
    echo "=============================================================="
}

# Головна функція
main() {
    echo -e "${BLUE}"
    echo "========================================="
    echo "  Скрипт встановлення для Ubuntu/Debian"
    echo "  Docker + Docker Compose + Python + Django"
    echo "========================================="
    echo -e "${NC}"
    
    # Перевірка системи
    check_system
    
    # Перевірка прав суперкористувача для деяких операцій
    if [[ $EUID -eq 0 ]]; then
        log_warning "Скрипт запущено від root. Рекомендується запускати від звичайного користувача."
    fi
    
    # Оновлення пакетів
    update_packages
    
    # Встановлення інструментів
    install_docker
    install_docker_compose
    install_python
    install_pip
    install_django
    
    # Перевірка встановлення
    echo
    verify_installation
    
    echo
    log_success "Встановлення завершено!"
}

# Запуск головної функції
main "$@"