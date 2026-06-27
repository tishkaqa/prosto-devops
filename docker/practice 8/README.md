# Задание 8: Troubleshooting - Контейнер умирает от логов

## Проблема

Контейнер падает через некоторое время работы. Логи забивают диск, контейнер умирает.

**Ваша задача:** Найти проблему и исправить.

---

## Диагностика

### Шаг 1: Запустить контейнер

```bash
cd d8
docker build -t log-app .
docker run -d -p 8080:8080 --name logtest log-app
```

### Шаг 2: Сделать несколько запросов

```bash
curl http://localhost:8080
curl http://localhost:8080
curl http://localhost:8080
```

### Шаг 3: Посмотреть логи

```bash
docker logs logtest
```

Сколько логов от трех запросов?

### Шаг 4: Проверить размер логов

```bash
# Размер лог-файла контейнера
docker inspect logtest --format='{{.LogPath}}' | xargs ls -lh

# Или через docker inspect
docker inspect logtest --format='{{.LogPath}}' | xargs du -h
```

### Шаг 5: Мониторинг логов в реальном времени

```bash
docker logs -f logtest
```

Открыть в браузере http://localhost:8080 и обновить страницу несколько раз.

**Смотрите как полетели логи**

---

## Поиск причины

ищите)))