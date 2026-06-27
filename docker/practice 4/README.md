# Задание 4: Docker Compose

## Цель

Автоматизировать запуск многоконтейнерного приложения с помощью Docker Compose.

---

## Структура docker-compose.yml

```yaml
version: '3.8'

services:
  db:           # Имя сервиса = hostname в сети
    image: ...  # Образ (для готовых) или build (для своих)
    environment:
      KEY: value
    volumes:
      - ./path:/container/path
    networks:
      - app-network

volumes:        # Именованные volumes
networks:       # Сети
```

---

## Задание

Написать `docker-compose.yml` для приложения из 3 контейнеров:

### Сервис `db`:
- Образ: `postgres:15-alpine`
- Переменные:
  - `POSTGRES_PASSWORD`
  - `POSTGRES_USER`
  - `POSTGRES_DB`
- Volumes:
  - `./db/init.sql:/docker-entrypoint-initdb.d/init.sql`
  - `pgdata:/var/lib/postgresql/data` (для персистентности)

### Сервис `backend`:
- Build из `./backend`
- Переменные:
  - `APP_NAME`
  - `DB_HOST` (имя сервиса `db`)
  - `DB_PORT`
- `depends_on: db` (запуск после БД)

### Сервис `frontend`:
- Build из `./frontend`
- Переменные:
  - `APP_NAME`
  - `BACKEND_URL` (формат: `http://backend:5000`)
- Порты: `8080:8080`
- `depends_on: backend`

### Общее:
- Все сервисы в одной сети `app-network`

---

## Ключевые директивы

### `depends_on`
Определяет порядок запуска контейнеров:
```yaml
depends_on: db
```

### `healthcheck`
Проверка работоспособности сервиса:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U appuser"]
  interval: 10s
  timeout: 3s
  retries: 3
```

### `volumes`
Два типа:
```yaml
volumes:
  - ./local:/container       # bind mount
  - named_volume:/container  # named volume
```

### `networks`
Автоматическое создание сети:
```yaml
networks:
  app-network:
    driver: bridge
```

---

## Выполнение

### Запуск всего стека:
```bash
docker-compose up -d
```

Флаги:
- `-d` - в фоне (detached)
- `--build` - пересобрать образы

### Проверка:
```bash
# Все контейнеры
docker-compose ps

# Логи всех сервисов
docker-compose logs

# Логи одного сервиса
docker-compose logs frontend

# Следить за логами
docker-compose logs -f
```

### Открыть в браузере:
```
http://localhost:8080
```

### Остановка:
```bash
docker-compose down
```