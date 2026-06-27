#!/bin/bash

# Скрипт для развертывания N контейнеров с полноценным Linux окружением
# Использование: ./deploy-containers.sh <количество контейнеров>

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода цветных сообщений
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

# Проверка аргументов
if [ $# -eq 0 ]; then
    log_error "Укажите количество контейнеров для развертывания"
    echo "Использование: $0 <количество>"
    echo "Пример: $0 5"
    exit 1
fi

NUM_CONTAINERS=$1

# Проверка, что аргумент является числом
if ! [[ "$NUM_CONTAINERS" =~ ^[0-9]+$ ]]; then
    log_error "Количество контейнеров должно быть положительным числом"
    exit 1
fi

# Проверка на разумное количество
if [ "$NUM_CONTAINERS" -gt 50 ]; then
    log_warning "Вы пытаетесь запустить более 50 контейнеров!"
    read -p "Продолжить? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Отменено пользователем"
        exit 0
    fi
fi

log_info "Начинаю развертывание $NUM_CONTAINERS контейнеров..."

# Проверка наличия Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker не установлен. Установите Docker и попробуйте снова."
    exit 1
fi

# Проверка наличия Docker Compose
if ! command -v docker-compose &> /dev/null; then
    log_error "Docker Compose не установлен. Установите Docker Compose и попробуйте снова."
    exit 1
fi

# Проверка наличия Dockerfile
if [ ! -f "Dockerfile" ]; then
    log_error "Dockerfile не найден в текущей директории"
    exit 1
fi

# Сборка базового образа
log_info "Сборка базового образа Linux..."
docker-compose build

log_success "Базовый образ собран успешно"

# Создание Docker сети
log_info "Проверка Docker сети..."
if ! docker network inspect linux-net &> /dev/null; then
    log_info "Создание сети linux-net..."
    docker network create --driver bridge linux-net
    log_success "Сеть linux-net создана"
else
    log_success "Сеть linux-net уже существует"
fi

# Создание контейнеров
log_info "Создание $NUM_CONTAINERS контейнеров..."

# Массив для хранения имен контейнеров
declare -a CONTAINER_NAMES

for i in $(seq 1 $NUM_CONTAINERS); do
    CONTAINER_NAME="linux-container-$i"
    CONTAINER_NAMES+=("$CONTAINER_NAME")

    log_info "Запуск контейнера: $CONTAINER_NAME"

    # Запуск контейнера с уникальным именем и hostname
    docker run -d \
        --name "$CONTAINER_NAME" \
        --hostname "linux-$i" \
        --privileged \
        --cgroupns=host \
        -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
        --tmpfs /run \
        --tmpfs /run/lock \
        --tmpfs /tmp \
        --network linux-net \
        --restart unless-stopped \
        -it \
        linux-full:latest

    if [ $? -eq 0 ]; then
        log_success "Контейнер $CONTAINER_NAME запущен успешно"
    else
        log_error "Не удалось запустить контейнер $CONTAINER_NAME"
    fi

    # Небольшая пауза между запусками
    sleep 0.5
done

echo ""
log_success "============================================"
log_success "  Все контейнеры успешно развернуты!"
log_success "============================================"
echo ""

# Вывод информации о запущенных контейнерах
log_info "Список запущенных контейнеров:"
echo ""
docker ps --filter "name=linux-container-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
log_info "Полезные команды:"
echo ""
echo "  Подключиться к контейнеру:"
echo "    docker exec -it linux-container-1 /bin/bash"
echo ""
echo "  Подключиться как пользователь 'user':"
echo "    docker exec -it -u user linux-container-1 /bin/bash"
echo ""
echo "  Просмотр логов контейнера:"
echo "    docker logs linux-container-1"
echo ""
echo "  Остановить все контейнеры:"
echo "    ./stop-containers.sh"
echo ""
echo "  Удалить все контейнеры:"
echo "    ./cleanup-containers.sh"
echo ""
log_info "SSH доступ (внутри контейнера):"
echo "  Пользователь root: password"
echo "  Пользователь user: password"
echo ""

# Сохранение списка контейнеров в файл
echo "${CONTAINER_NAMES[@]}" > .container_list
log_success "Список контейнеров сохранен в .container_list"