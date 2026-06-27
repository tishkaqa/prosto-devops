# Задание 10: Контейнеры крашатся - найди все проблемы

## Проблема
6 контейнеров, все с проблемами. Ничего не работает.

## Запуск
```bash
cd d10
docker-compose up
# Смотри на ошибки
```

## Диагностика
```bash
# Статус контейнеров
docker-compose ps

# Логи
docker-compose logs app1
docker-compose logs app6

# Exit codes
docker inspect app4 --format='{{.State.ExitCode}}'
docker inspect app5 --format='{{.State.ExitCode}}'

# Проверка портов
docker ps -a | grep 8080
```

## 6 проблем:

**1. app1 - нет конфига**
```
Error: ./config/app1.conf not found
Fix: cp config/app1.conf.example config/app1.conf
```

**2. app2 - конфликт портов**
```
Error: port 8080 already in use
Fix: Изменить порт на 8081:80
```

**3. app3 - read-only volume**
```
Error: Read-only file system
Fix: Убрать :ro или создать ./data директорию с правами
```

**4. app4 - exit 0 при ошибке**
```
Fix: Убрать "|| exit 0", использовать set -e
```

**5. app5 - restart loop**
```
Fix: Изменить restart: always на restart: "no"
```

**6. app6 - нет обязательной env**
```
Error: POSTGRES_PASSWORD not set
Fix: Добавить environment: POSTGRES_PASSWORD: secret
```
