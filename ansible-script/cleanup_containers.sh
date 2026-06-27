#!/bin/bash

# Скрипт для удаления всех Linux контейнеров

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Получение списка контейнеров
CONTAINERS=$(docker ps -a --filter "name=linux-container-" --format "{{.Names}}")

if [ -z "$CONTAINERS" ]; then
    log_info "Контейнеры не найдены"
    exit 0
fi

log_warning "Будут удалены следующие контейнеры:"
echo "$CONTAINERS"
echo ""

read -p "Продолжить удаление? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "Отменено пользователем"
    exit 0
fi

log_info "Остановка и удаление контейнеров..."

# Остановка и удаление каждого контейнера
for container in $CONTAINERS; do
    log_info "Удаление $container..."
    docker stop "$container" 2>/dev/null || true
    docker rm "$container"
    log_success "$container удален"
done

# Удаление файла со списком контейнеров
if [ -f ".container_list" ]; then
    rm .container_list
    log_info "Файл .container_list удален"
fi

log_success "Все контейнеры удалены"

# Опция для удаления образа
echo ""
read -p "Удалить также образ linux-full:latest? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Удаление образа linux-full:latest..."
    docker rmi linux-full:latest
    log_success "Образ удален"
fi

# Опция для удаления сети
echo ""
read -p "Удалить также сеть linux-net? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if docker network inspect linux-net &> /dev/null; then
        log_info "Удаление сети linux-net..."
        docker network rm linux-net
        log_success "Сеть удалена"
    else
        log_info "Сеть linux-net не найдена"
    fi
fi

log_success "Очистка завершена"