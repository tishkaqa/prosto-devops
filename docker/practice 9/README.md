# Задание 9: Troubleshooting Docker Networks

## Проблема
5 контейнеров в 3 разных сетях. Ничего не работает.

## Симптомы
- Redis изолирован - никто не может подключиться
- Frontend не видит API
- Worker использует хардкод IP 192.168.1.100 (несуществующий)
- backend_net помечена `internal: true` - контейнеры не могут наружу

## Запуск
```bash
cd d9
docker-compose up -d
docker-compose logs worker  # Видно проблему с IP
```

## Диагностика
```bash
# Проверить сети
docker network ls
docker network inspect d9_redis_net
docker network inspect d9_backend_net

# Попробовать ping между контейнерами
docker exec frontend ping -c 2 api        # Fail - разные сети
docker exec worker ping -c 2 redis        # Fail - разные сети
docker exec api ping -c 2 db              # OK - одна сеть

# Проверить internal
docker network inspect d9_backend_net --format '{{.Internal}}'  # true
```

## Найдите и исправьте 4 проблемы:
1. Redis в отдельной сети - добавьте его в backend_net
2. Frontend не видит API - добавьте frontend в backend_net
3. Worker использует IP - замените на имя сервиса (redis)
4. backend_net internal - уберите `internal: true`

## Проверка после фикса
```bash
docker-compose down
# Исправить docker-compose.yml
docker-compose up -d
docker exec worker ping -c 2 redis   # OK
docker exec frontend ping -c 2 api   # OK
```
