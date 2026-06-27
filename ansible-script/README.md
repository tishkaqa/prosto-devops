# ANSIBLE DOCKER КОНТЕЙНЕРЫ - БЫСТРЫЙ СТАРТ

# 1. Развернуть 3 контейнера
./deploy_containers.sh 3

# 2. Сгенерировать inventory
./generate_ansible_inventory.sh

# 3. Проверить подключение
ansible all -m ping

# 4. Выполнить команду на всех хостах
ansible all -a "команда"

# 5. Примеры команд
ansible all -a "hostname"              # Показать имена хостов
ansible all -a "df -h"                  # Диски
ansible all -m shell -a "uptime"        # Uptime
ansible all -m setup                    # Собрать все факты

# 6. Очистка
./cleanup_containers.sh

# ВАЖНО:
# - Используется ansible_connection=docker
# - Контейнеры доступны по именам linux-container-1,2,3
# - Логи в ansible.log