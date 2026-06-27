# Задание 6: Оптимизация Dockerfile - Best Practices

## Цель

Переписать плохой Dockerfile, применив все best practices для production.

---

## Проблема

В файле `Dockerfile.bad` собраны **все возможные антипаттерны**:
- Огромный размер образа
- Медленная сборка
- Проблемы с безопасностью
- Плохое кэширование
- Запуск от root

**Ваша задача:** Создать оптимизированный `Dockerfile`, исправив все проблемы.

---

## Best Practices

### 1. Использовать конкретные теги

❌ **Плохо:**
```dockerfile
FROM python:latest
```

✅ **Хорошо:**
```dockerfile
FROM python:3.11-slim
```

**Почему:**
- `latest` может измениться в любой момент
- Нет воспроизводимости сборки
- В production нужны предсказуемые версии

**Правило:** Всегда указывайте **конкретную версию**.

---

### 2. Использовать slim/alpine образы

❌ **Плохо:**
```dockerfile
FROM python:3.11        # ~900 MB
```

✅ **Хорошо:**
```dockerfile
FROM python:3.11-slim   # ~150 MB
FROM python:3.11-alpine # ~50 MB (но могут быть проблемы с C-библиотеками)
```

**Почему:**
- Меньше размер → быстрее скачивание и деплой
- Меньше уязвимостей
- Меньше ненужных пакетов

**Правило:** Для Python используйте `-slim`, для Node.js - `-alpine`.

---

### 3. Минимизировать количество слоев

❌ **Плохо:**
```dockerfile
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y wget
RUN apt-get install -y git
```

✅ **Хорошо:**
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
```

**Почему:**
- Каждый `RUN` = новый слой = больше размер
- Объединение команд уменьшает размер образа
- Очистка кэша экономит место

**Правило:** Объединяйте связанные команды в один `RUN` через `&&`.

---

### 4. Правильный порядок COPY (кэширование)

❌ **Плохо:**
```dockerfile
COPY . /app
RUN pip install -r requirements.txt
```

При любом изменении кода переустанавливаются все зависимости!

✅ **Хорошо:**
```dockerfile
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
```

**Почему:**
- Docker кэширует слои
- Зависимости меняются редко → кэш работает
- Код меняется часто → пересобирается только последний слой

**Правило:** Сначала копируйте файлы зависимостей, потом код.

---

### 5. Использовать .dockerignore

❌ **Плохо:**
```dockerfile
COPY . /app
# Копируется ВСЁ: .git, __pycache__, node_modules, .env, etc.
```

✅ **Хорошо:**

Создать `.dockerignore`:
```
.git
.gitignore
__pycache__
*.pyc
.pytest_cache
.venv
venv/
node_modules/
.env
*.md
.DS_Store
```

**Почему:**
- Уменьшает размер образа
- Ускоряет сборку
- Не попадают секреты

**Правило:** Всегда создавайте `.dockerignore`.

---

### 6. Не запускать от root

❌ **Плохо:**
```dockerfile
# По умолчанию все команды выполняются от root
CMD ["python", "app.py"]
```

✅ **Хорошо:**
```dockerfile
RUN useradd -m -u 1001 appuser
# или просто
USER 1001

CMD ["python", "app.py"]
```

**Почему:**
- Безопасность: если приложение скомпрометировано, атакующий не получит root
- Best practice для production

**Правило:** Всегда используйте `USER` для непривилегированного пользователя.

---

### 7. Использовать exec форму CMD/ENTRYPOINT

❌ **Плохо (shell форма):**
```dockerfile
CMD python app.py
```

✅ **Хорошо (exec форма):**
```dockerfile
CMD ["python", "app.py"]
```

**Почему:**
- Shell форма запускает `/bin/sh -c "python app.py"` → лишний процесс
- Сигналы (SIGTERM) не доходят до приложения корректно
- PID 1 должен быть вашим приложением, а не shell

**Правило:** Используйте JSON-массив `["python", "app.py"]`.

---

### 8. Добавить metadata (LABEL)

❌ **Плохо:**
```dockerfile
# Нет информации об образе
```

✅ **Хорошо:**
```dockerfile
LABEL maintainer="devops@example.com"
LABEL version="1.0.0"
LABEL description="Production app"
```

**Почему:**
- Документация образа
- Можно фильтровать образы по label
- Полезно для CI/CD

**Правило:** Добавляйте основные метаданные.

---

### 9. Указать EXPOSE

❌ **Плохо:**
```dockerfile
# Не понятно, какой порт использует приложение
```

✅ **Хорошо:**
```dockerfile
EXPOSE 8080
```

**Почему:**
- Документация: какой порт слушает приложение
- Используется в docker-compose
- Не влияет на безопасность (только документация)

**Правило:** Всегда указывайте `EXPOSE`.

---

### 10. Очищать кэши пакетных менеджеров

❌ **Плохо:**
```dockerfile
RUN apt-get update && apt-get install -y curl
RUN pip install -r requirements.txt
```

✅ **Хорошо:**
```dockerfile
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir -r requirements.txt
```

**Почему:**
- Кэши занимают место (сотни MB)
- В образе они не нужны

**Правило:**
- apt: `--no-install-recommends`, `apt-get clean`, `rm -rf /var/lib/apt/lists/*`
- pip: `--no-cache-dir`
- npm: `npm ci --only=production` + `npm cache clean --force`

---

### 11. Не хранить секреты в образе

❌ **ОЧЕНЬ ПЛОХО:**
```dockerfile
ENV DATABASE_PASSWORD=secret123
ENV API_KEY=sk-abc123
```

✅ **Хорошо:**
```dockerfile
# Передавайте секреты через docker run или docker-compose
# docker run -e DATABASE_PASSWORD=$DB_PASS myapp
```

**Почему:**
- Секреты останутся в слоях образа НАВСЕГДА
- Даже если удалить ENV, секрет можно извлечь из истории
- Критическая уязвимость безопасности

**Правило:**
- Используйте переменные окружения при запуске
- Или Docker Secrets (Swarm)
- Или внешние хранилища (Vault, AWS Secrets Manager)

---

### 12. Использовать multi-stage builds (опционально)

✅ **Продвинутая оптимизация:**
```dockerfile
# Stage 1: Build
FROM python:3.11 AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY . .
ENV PATH=/root/.local/bin:$PATH
CMD ["python", "app.py"]
```

**Почему:**
- Финальный образ не содержит build-зависимости
- Еще меньше размер

---

### 13. Использовать WORKDIR

❌ **Плохо:**
```dockerfile
RUN cd /app && python app.py
```

✅ **Хорошо:**
```dockerfile
WORKDIR /app
CMD ["python", "app.py"]
```

**Почему:**
- `WORKDIR` создает директорию автоматически
- Устанавливает рабочую директорию для всех последующих команд
- Более читаемо

**Правило:** Всегда используйте `WORKDIR`.

---

### 14. Добавить HEALTHCHECK (опционально)

✅ **Хорошо:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080')" || exit 1
```

**Почему:**
- Docker может автоматически перезапускать нездоровые контейнеры
- Используется оркестраторами (Kubernetes, Swarm)

---

## Сравнение размеров

| Оптимизация | Размер образа |
|-------------|---------------|
| `FROM python` | ~900 MB |
| `FROM python:3.11-slim` | ~150 MB |
| + Очистка кэша apt/pip | ~130 MB |
| + .dockerignore | ~120 MB |
| + Multi-stage | ~100 MB |
| `FROM python:3.11-alpine` | ~50 MB |

---

## Задание

### Шаг 1: Изучить плохой Dockerfile

Откройте `Dockerfile.bad` и найдите все антипаттерны (их 16!).

### Шаг 2: Создать оптимизированный Dockerfile

Создайте файл `Dockerfile` и примените все best practices.

**Чек-лист:**
- ✅ Конкретный тег (не `latest`)
- ✅ Slim/Alpine образ
- ✅ Минимум слоев (объединенные RUN)
- ✅ Правильный порядок COPY
- ✅ Очистка кэшей (apt, pip)
- ✅ USER (не root)
- ✅ Exec форма CMD
- ✅ LABEL метаданные
- ✅ EXPOSE порт
- ✅ WORKDIR
- ✅ Нет секретов в ENV
- ✅ .dockerignore файл