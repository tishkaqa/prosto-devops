# Database Container

Этот контейнер использует готовый образ PostgreSQL.

## Запуск

```bash
docker run -d \
  --name db \
  --network myapp-network \
  -e POSTGRES_PASSWORD=secret123 \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_DB=myappdb \
  -v $(pwd)/init.sql:/docker-entrypoint-initdb.d/init.sql \
  postgres:15-alpine
```

## Переменные окружения

- `POSTGRES_PASSWORD` - пароль для БД (обязательно!)
- `POSTGRES_USER` - имя пользователя (по умолчанию: postgres)
- `POSTGRES_DB` - имя базы данных (по умолчанию: postgres)

## Инициализация

Файл `init.sql` автоматически выполнится при первом запуске контейнера.
Он создаст таблицы и заполнит их тестовыми данными.

## Проверка

```bash
# Подключение к БД
docker exec -it db psql -U appuser -d myappdb

# SQL запросы
SELECT * FROM users;
SELECT * FROM logs;
```
