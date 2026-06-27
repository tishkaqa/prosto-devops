# Задание 3: Многоконтейнерное приложение с Docker Networks

## Цель

Развернуть приложение из 3 контейнеров **БЕЗ docker-compose**, настроить сеть между ними.

---

## Архитектура

```
┌─────────────┐
│  Frontend   │  <- Пользователь заходит сюда (http://localhost:8080)
│   :8080     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Backend   │  <- API (порт 5000)
│   :5000     │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Database   │  <- PostgreSQL (порт 5432)
│   :5432     │
└─────────────┘
```

**Ключевой момент**: Все контейнеры должны быть в одной Docker-сети!

---

## Структура проекта

```
d3/
├── frontend/
│   ├── Dockerfile
│   └── app.py
├── backend/
│   ├── Dockerfile
│   └── app.py
├── db/
│   ├── init.sql
│   └── README.md
└── TASK.md
```

---

## Что такое Docker Networks

Docker Networks позволяют контейнерам общаться друг с другом по именам.

### Типы сетей:
- **bridge** (по умолчанию) - контейнеры на одном хосте
- **host** - контейнер использует сеть хоста
- **none** - без сети

Мы будем использовать **bridge**.

---

## Пошаговое выполнение

### Шаг 1: Создать Docker-сеть

```bash
docker network create myapp-network
```

Проверить:
```bash
docker network ls
docker network inspect myapp-network
```

---

### Шаг 2: Запустить базу данных

База данных **не требует Dockerfile** - используем готовый образ PostgreSQL.

```bash
docker run -d \
  --name db \
  --network myapp-network \
  -e POSTGRES_PASSWORD=secret123 \
  -e POSTGRES_USER=appuser \
  -e POSTGRES_DB=myappdb \
  -v $(pwd)/db/init.sql:/docker-entrypoint-initdb.d/init.sql \
  postgres:15-alpine
```

**Важно**:
- `--name db` - имя контейнера = имя хоста в сети
- `--network myapp-network` - подключение к нашей сети
- `-v $(pwd)/db/init.sql:...` - монтирование SQL-скрипта для инициализации
- Порты НЕ пробрасываем наружу! Только внутри сети.

Проверить:
```bash
docker logs db
```

Должно быть: `database system is ready to accept connections`

#### Проверить данные в БД:

```bash
docker exec -it db psql -U appuser -d myappdb -c "SELECT * FROM users;"
```

---

### Шаг 3: Собрать и запустить Backend

**Собрать образ**

**Запустить контейнер:**

**Важно**:
указать --network и название сети, которую вы создали и где запустили базу
передать переменную окружения DB_HOST=название контейнера с базой
передать переменную окружения DB_PORT=5432

- `--name` = имя контейнера = имя хоста для тех, кто к нему хочет подключится
- Порт 5000 НЕ пробрасываем наружу!

Проверить:
```bash
docker logs backend
```

---

### Шаг 4: Собрать и запустить Frontend

**Собрать образ:**
```bash
cd frontend
docker build -t myapp-frontend .
cd ..
```

**Запустить контейнер:**
  --name frontend 
  --network название сети
  -e BACKEND_URL=http://backend:5000 \
  -p 8080:8080 \

**Важно**:
- `-e BACKEND_URL=http://backend:5000` - обращение к backend по имени
- `-p 8080:8080` - **ТОЛЬКО frontend** доступен снаружи!

---

### Шаг 5: Проверка работы

#### 1. Проверить все контейнеры:
```bash
docker ps
```

Должны быть запущены: `frontend`, `backend`, `db`

#### 2. Открыть в браузере:
```
http://localhost:8080
```

Вы должны увидеть Frontend, который подключается к Backend.

#### 3. Проверить сеть:
```bash
docker network inspect myapp-network
```

## Как работает сеть

1. **Все контейнеры в одной сети** (`myapp-network`)
2. **DNS внутри сети**: Docker автоматически разрешает имена контейнеров
3. **Frontend** обращается к `http://backend:5000` - имя `backend` резолвится в IP контейнера
4. **Backend** обращается к `db:5432` - имя `db` резолвится в IP контейнера БД
5. **Только Frontend** доступен снаружи через `-p 8080:8080`

---

## Схема проброса портов

```
Внешний мир → :8080 → Frontend → backend:5000 → Backend → db:5432 → Database
              (публ.)           (внутри сети)           (внутри сети)
```

**Важно**: Backend и Database НЕ доступны снаружи - только через Frontend!

---

## Управление

### Остановить все контейнеры:
```bash
docker stop frontend backend db
```

### Удалить контейнеры:
```bash
docker rm frontend backend db
```

### Удалить сеть:
```bash
docker network rm myapp-network
```

### Удалить образы:
```bash
docker rmi myapp-frontend myapp-backend
```

### Полная очистка (одной командой):
```bash
docker stop frontend backend db && \
docker rm frontend backend db && \
docker network rm myapp-network && \
docker rmi myapp-frontend myapp-backend
```

---

## Переменные окружения

### Frontend:
- `APP_NAME` - название приложения
- `BACKEND_URL` - URL backend сервиса (формат: `http://backend:5000`)

### Backend:
- `APP_NAME` - название приложения
- `DB_HOST` - хост базы данных (имя контейнера `db`)
- `DB_PORT` - порт БД (по умолчанию `5432`)

### Database:
- `POSTGRES_PASSWORD` - пароль (обязательно!)
- `POSTGRES_USER` - имя пользователя
- `POSTGRES_DB` - имя базы данных

---

## Типичная ошибка

### Порт уже занят

**Причина**: Порт 8080 используется другим приложением.

**Решение**: Изменить проброс порта:
```bash
docker run -d --name frontend --network myapp-network -p 8081:8080 myapp-frontend
```
---

## Диагностика

### Проверить логи:
```bash
docker logs frontend
docker logs backend
docker logs db
```