#!/bin/bash

# Скрипт для генерации Ansible inventory из запущенных контейнеров

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Имя выходного файла
INVENTORY_FILE="${1:-inventory.ini}"
INVENTORY_YAML="${2:-inventory.yml}"

log_info "Генерация Ansible inventory..."

# Получение списка запущенных контейнеров
CONTAINERS=$(docker ps --filter "name=linux-container-" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    log_warning "Нет запущенных контейнеров!"
    echo "Запустите контейнеры командой: ./deploy-containers.sh <количество>"
    exit 1
fi

# Подсчет контейнеров
CONTAINER_COUNT=$(echo "$CONTAINERS" | wc -l)
log_info "Найдено контейнеров: $CONTAINER_COUNT"

# Генерация INI inventory
log_info "Создание $INVENTORY_FILE..."

cat > "$INVENTORY_FILE" << 'EOF'
# Ansible Inventory для Linux контейнеров
# Сгенерирован автоматически

[linux_containers]
EOF

# Добавление каждого контейнера
for container in $CONTAINERS; do
    # Получение IP адреса контейнера
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")

    # Извлечение номера контейнера
    NUM=$(echo "$container" | sed 's/linux-container-//')

    echo "$container ansible_connection=docker" >> "$INVENTORY_FILE"
done

# Добавление переменных группы
cat >> "$INVENTORY_FILE" << 'EOF'

[linux_containers:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

# Группы по назначению (примеры)
[webservers]
# Добавьте сюда веб-серверы

[databases]
# Добавьте сюда базы данных

[appservers]
# Добавьте сюда app-серверы
EOF

log_success "INI inventory создан: $INVENTORY_FILE"

# Генерация YAML inventory
log_info "Создание $INVENTORY_YAML..."

cat > "$INVENTORY_YAML" << 'EOF'
---
all:
  children:
    linux_containers:
      hosts:
EOF

# Добавление хостов в YAML формате
for container in $CONTAINERS; do
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")

    cat >> "$INVENTORY_YAML" << EOF
        $container:
          ansible_connection: docker
EOF
done

# Добавление переменных в YAML
cat >> "$INVENTORY_YAML" << 'EOF'
      vars:
        ansible_python_interpreter: /usr/bin/python3
        ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

    # Группы по назначению (примеры)
    webservers:
      hosts: {}

    databases:
      hosts: {}

    appservers:
      hosts: {}
EOF

log_success "YAML inventory создан: $INVENTORY_YAML"

echo ""
log_success "============================================"
log_success "  Ansible inventory готов к использованию"
log_success "============================================"
echo ""

log_info "Список хостов в inventory:"
echo ""
for container in $CONTAINERS; do
    IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
    echo "  $container -> $IP"
done

echo ""
log_info "Быстрая проверка подключения:"
echo ""
echo "  # Проверить INI inventory"
echo "  ansible all -i $INVENTORY_FILE -m ping"
echo ""
echo "  # Проверить YAML inventory"
echo "  ansible all -i $INVENTORY_YAML -m ping"
echo ""
echo "  # Выполнить команду на всех хостах"
echo "  ansible all -i $INVENTORY_FILE -a 'hostname'"
echo ""
echo "  # Запустить плейбук"
echo "  ansible-playbook -i $INVENTORY_FILE playbook.yml"
echo ""

log_info "Примечание: Используется ansible_connection=docker для прямого подключения к контейнерам"