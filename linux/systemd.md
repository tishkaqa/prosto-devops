# SystemD и Unit-файлы

## Зачем это знать?

- Запустить приложение как системный сервис (чтобы стартовало при загрузке)
- Настроить автоматический перезапуск при падении
- Запускать задачи по расписанию (замена cron)
- Управлять зависимостями между сервисами (БД → Приложение → Nginx)
- Смотреть логи сервиса
- Понять почему сервис не запустился

**SystemD** — это система инициализации и управления сервисами в современных Linux дистрибутивах (начиная с Ubuntu 15.04, CentOS 7, Debian 8).

На собеседованиях часто спрашивают:
- Как создать systemd сервис?
- В чем разница между `After` и `Requires`?
- Какие типы юнитов бывают?

Давай разберемся.

---

## 1. Что такое SystemD Unit?

### Определение

**Unit** — это конфигурационный файл, описывающий системный ресурс: сервис, устройство, точку монтирования, таймер и т.д. 

Это основная единица управления в systemd.

### Типы Units

| Тип | Расширение | Назначение | Пример |
|-----|-----------|------------|---------|
| **Service** | `.service` | Сервисы (демоны, приложения) | nginx.service, postgresql.service |
| **Timer** | `.timer` | Таймеры (замена cron) | backup.timer |
| **Socket** | `.socket` | Сокеты для активации сервисов | docker.socket |
| **Mount** | `.mount` | Точки монтирования | home.mount |
| **Target** | `.target` | Группы юнитов (аналог runlevel) | multi-user.target |
| **Path** | `.path` | Мониторинг файлов/директорий | logwatch.path |

**Самый важный тип для DevOps** — это `.service`

---

## 2. Структура Service Unit файла

Service Unit состоит из трех основных секций:

```ini
[Unit]
# Метаданные и зависимости

[Service]
# Как запускать и контролировать процесс

[Install]
# Как интегрировать в систему
```

Давай разберем каждую секцию.

---

### Секция [Unit] — Метаданные

Общая информация о сервисе и его зависимости.

**Основные параметры:**

| Параметр | Описание | Пример |
|----------|----------|--------|
| `Description` | Описание сервиса | `Description=My Web Application` |
| `After` | Запустить ПОСЛЕ указанных юнитов | `After=network.target` |
| `Before` | Запустить ПЕРЕД указанными юнитами | `Before=nginx.service` |
| `Requires` | Жесткая зависимость (без них не запустится) | `Requires=postgresql.service` |
| `Wants` | Мягкая зависимость (попытается запустить) | `Wants=redis.service` |
| `ConditionPathExists` | Условие существования пути | `ConditionPathExists=/etc/myapp/config.yml` |

**Пример:**

```ini
[Unit]
Description=My Web Application
Documentation=https://docs.myapp.com
After=network.target postgresql.service
Requires=postgresql.service
Wants=redis.service
```

---

### Секция [Service] — Управление процессом

Как запускать и контролировать сервис.

**Основные параметры:**

| Параметр | Описание | Пример |
|----------|----------|--------|
| `Type` | Тип процесса | `Type=simple` |
| `ExecStart` | Команда запуска | `ExecStart=/usr/bin/myapp` |
| `ExecStop` | Команда остановки | `ExecStop=/usr/bin/myapp stop` |
| `ExecReload` | Перезагрузка без остановки | `ExecReload=/bin/kill -HUP $MAINPID` |
| `Restart` | Политика перезапуска | `Restart=on-failure` |
| `RestartSec` | Задержка перед перезапуском | `RestartSec=5s` |
| `User` | От какого пользователя запускать | `User=www-data` |
| `Group` | Группа пользователя | `Group=www-data` |
| `WorkingDirectory` | Рабочая директория | `WorkingDirectory=/var/www/myapp` |
| `Environment` | Переменные окружения | `Environment="NODE_ENV=production"` |
| `EnvironmentFile` | Файл с переменными | `EnvironmentFile=/etc/myapp/env` |

**Пример:**

```ini
[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
Environment="PORT=8080"
EnvironmentFile=/etc/myapp/env
ExecStart=/usr/bin/node /opt/myapp/server.js
Restart=on-failure
RestartSec=5s
```

---

### Секция [Install] — Интеграция

Как включить сервис в систему.

**Основные параметры:**

| Параметр | Описание | Пример |
|----------|----------|--------|
| `WantedBy` | К какому target привязать | `WantedBy=multi-user.target` |
| `RequiredBy` | Кто требует этот сервис | `RequiredBy=some-other.service` |
| `Alias` | Альтернативное имя | `Alias=myapp.service` |

**Пример:**

```ini
[Install]
WantedBy=multi-user.target
```

**Что такое `multi-user.target`?**

Это аналог runlevel 3 (многопользовательский режим без GUI). Большинство сервисов привязываются к этому target.

---

## 3. Типы сервисов (Type)

Определяет как systemd управляет процессом.

### simple (по умолчанию)

**Описание:**
- Процесс не делает fork
- Работает на переднем плане
- systemd считает что сервис готов сразу после запуска

**Когда использовать:**
- Современные приложения (Node.js, Python, Go)
- Приложения которые не уходят в фон

**Пример:**

```ini
[Service]
Type=simple
ExecStart=/usr/bin/node /opt/app/server.js
```

---

### forking

**Описание:**
- Процесс делает fork и родительский процесс завершается
- Работает в фоне (классический демон)
- systemd ждет завершения родительского процесса

**Когда использовать:**
- Классические демоны (Nginx, Apache в некоторых режимах)
- Приложения которые сами уходят в фон

**Пример:**

```ini
[Service]
Type=forking
PIDFile=/var/run/myapp.pid
ExecStart=/usr/sbin/myapp --daemon
```

**Важно:** Нужно указать `PIDFile` чтобы systemd знал PID основного процесса.

---

### oneshot

**Описание:**
- Разовая задача
- Завершается после выполнения
- systemd ждет завершения перед запуском следующих юнитов

**Когда использовать:**
- Скрипты инициализации
- Разовые задачи (создание директорий, загрузка данных)

**Пример:**

```ini
[Service]
Type=oneshot
ExecStart=/usr/local/bin/setup-database.sh
RemainAfterExit=yes
```

**`RemainAfterExit=yes`** — считать сервис активным даже после завершения скрипта.

---

### notify

**Описание:**
- Приложение само уведомляет systemd когда готово (через `sd_notify()`)
- systemd ждет уведомления перед запуском зависимых сервисов

**Когда использовать:**
- Современные приложения с поддержкой systemd notify (PostgreSQL, nginx с модулем)

**Пример:**

```ini
[Service]
Type=notify
ExecStart=/usr/bin/myapp
```

---

### Сравнительная таблица

| Type | Fork? | Когда готов? | Use case |
|------|-------|-------------|----------|
| **simple** | Нет | Сразу после запуска | Node.js, Python Flask, Go-приложения |
| **forking** | Да | После fork и выхода родителя | Nginx, Apache (daemon mode) |
| **oneshot** | Нет | После завершения скрипта | Инициализация, скрипты |
| **notify** | Нет | Когда приложение уведомит | PostgreSQL, современные демоны |

**Вопрос на собеседовании:** "В чем разница между Type=simple и Type=forking?"

**Ответ:**
- **simple** — процесс работает на переднем плане, systemd считает что сервис готов сразу
- **forking** — процесс уходит в фон через fork, systemd ждет завершения родительского процесса и отслеживает PID дочернего

---

## 4. Политики перезапуска (Restart)

Определяет когда systemd перезапускает сервис.

| Значение | Когда перезапускает | Use case |
|----------|-------------------|----------|
| `no` | Никогда | Задачи которые должны выполниться один раз |
| `always` | Всегда (даже при чистом выходе) | Критичные сервисы которые должны всегда работать |
| `on-failure` | Только при ненулевом exit code | Большинство сервисов (рекомендуется) |
| `on-abnormal` | При сигналах/timeout | Для отладки |
| `on-abort` | При некорректном завершении | Редко используется |
| `on-watchdog` | При срабатывании watchdog | С Type=notify |

**Рекомендация:** Для production сервисов используй `Restart=on-failure`

**Пример:**

```ini
[Service]
Type=simple
ExecStart=/usr/bin/myapp
Restart=on-failure
RestartSec=5s
StartLimitBurst=5
StartLimitIntervalSec=10s
```

**Дополнительные параметры:**

- `RestartSec=5s` — подождать 5 секунд перед перезапуском
- `StartLimitBurst=5` — максимум 5 попыток перезапуска
- `StartLimitIntervalSec=10s` — в течение 10 секунд

Это защищает от бесконечных перезапусков при ошибке конфигурации.

---

## Зависимости между сервисами

### After vs Before

Определяет **порядок** запуска, но НЕ зависимость.

**`After`** — запустить ПОСЛЕ:

```ini
[Unit]
After=network.target postgresql.service
```

Это значит: "Запусти меня после сети и PostgreSQL, но если их нет — все равно запусти меня"

**`Before`** — запустить ПЕРЕД:

```ini
[Unit]
Before=nginx.service
```

---

### Requires vs Wants

Определяет **зависимость**.

**`Requires`** — жесткая зависимость:

```ini
[Unit]
Requires=postgresql.service
```

Это значит: "Если PostgreSQL не запустится — я тоже не запущусь. Если PostgreSQL упадет — останови меня."

**`Wants`** — мягкая зависимость:

```ini
[Unit]
Wants=redis.service
```

Это значит: "Попытайся запустить Redis, но если не получится — не страшно, я все равно запущусь"

---

### Комбинация After + Requires

**Правильная комбинация:**

```ini
[Unit]
Description=My Web Application
After=postgresql.service
Requires=postgresql.service
```

**Что это дает:**

1. Сначала запустится PostgreSQL (`After`)
2. Если PostgreSQL не запустится — приложение тоже не запустится (`Requires`)
3. Если PostgreSQL упадет — приложение тоже остановится (`Requires`)

**Вопрос на собеседовании:** "В чем разница между After и Requires?"

**Ответ:**
- **After** — определяет порядок запуска (КОГДА), но не обязывает
- **Requires** — определяет зависимость (БЕЗ ЧЕГО не запустится), но не порядок
- Обычно используют вместе: `After=foo.service` + `Requires=foo.service`

---

## 6. Где хранятся Unit файлы

SystemD ищет юниты в нескольких местах с разным приоритетом:

```
/etc/systemd/system/       ← ЗДЕСЬ создаем свои сервисы (высший приоритет)
/run/systemd/system/       ← временные runtime юниты
/usr/lib/systemd/system/   ← файлы из пакетов (не редактируй их!)
```

**Приоритет:** `/etc/systemd/system/` > `/run/systemd/system/` > `/usr/lib/systemd/system/`

**Правило:** Всегда создавай свои юниты в `/etc/systemd/system/`

---

## 7. Создание своего сервиса — пример

### Задача

Запустить Node.js приложение как systemd сервис.

**Приложение:**
- Путь: `/opt/myapp/server.js`
- Пользователь: `myapp`
- Порт: 3000
- Должен перезапускаться при падении
- Зависит от PostgreSQL

---

### Шаг 1: Создать пользователя

```bash
sudo useradd -r -s /bin/false myapp
```

---

### Шаг 2: Создать unit файл

```bash
sudo nano /etc/systemd/system/myapp.service
```

**Содержимое:**

```ini
[Unit]
Description=My Node.js Application
Documentation=https://docs.myapp.com
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
Environment="NODE_ENV=production"
Environment="PORT=3000"
ExecStart=/usr/bin/node /opt/myapp/server.js
Restart=on-failure
RestartSec=5s
StandardOutput=journal
StandardError=journal
SyslogIdentifier=myapp

[Install]
WantedBy=multi-user.target
```

**Что здесь происходит:**

- `After=postgresql.service` — запуск после PostgreSQL
- `Requires=postgresql.service` — не запустится без PostgreSQL
- `Type=simple` — процесс на переднем плане
- `User=myapp` — запуск от пользователя myapp
- `Restart=on-failure` — перезапуск при падении
- `StandardOutput=journal` — логи в systemd journal
- `WantedBy=multi-user.target` — запускать при загрузке системы

---

### Шаг 3: Перезагрузить systemd

```bash
sudo systemctl daemon-reload
```

**Важно:** После любых изменений в unit файлах нужно выполнить `daemon-reload`!

---

### Шаг 4: Включить автозапуск

```bash
sudo systemctl enable myapp.service
```

Это создаст symlink в `/etc/systemd/system/multi-user.target.wants/myapp.service`

---

### Шаг 5: Запустить сервис

```bash
sudo systemctl start myapp.service
```

---

### Шаг 6: Проверить статус

```bash
sudo systemctl status myapp.service
```

Вывод:

```
● myapp.service - My Node.js Application
   Loaded: loaded (/etc/systemd/system/myapp.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2025-01-20 10:00:00 UTC; 5s ago
 Main PID: 12345 (node)
    Tasks: 11 (limit: 4915)
   Memory: 45.2M
   CGroup: /system.slice/myapp.service
           └─12345 /usr/bin/node /opt/myapp/server.js
```

---

## 8. Основные команды systemctl

### Управление сервисами

```bash
# Запустить
sudo systemctl start myapp.service

# Остановить
sudo systemctl stop myapp.service

# Перезапустить
sudo systemctl restart myapp.service

# Перезагрузить конфиг без остановки (если поддерживается)
sudo systemctl reload myapp.service

# Перезапустить или перезагрузить (reload если можно)
sudo systemctl reload-or-restart myapp.service

# Статус
sudo systemctl status myapp.service
```

---

### Автозапуск

```bash
# Включить автозапуск при загрузке
sudo systemctl enable myapp.service

# Отключить автозапуск
sudo systemctl disable myapp.service

# Проверить включен ли автозапуск
sudo systemctl is-enabled myapp.service
```

---

### Просмотр юнитов

```bash
# Список всех сервисов
systemctl list-units --type=service

# Список всех сервисов (включая неактивные)
systemctl list-units --type=service --all

# Список включенных сервисов
systemctl list-unit-files --type=service --state=enabled

# Дерево зависимостей
systemctl list-dependencies myapp.service
```

---

### Работа с юнитами

```bash
# Перезагрузить systemd после изменения юнитов
sudo systemctl daemon-reload

# Посмотреть содержимое юнита
systemctl cat myapp.service

# Редактировать юнит (создает override)
sudo systemctl edit myapp.service

# Редактировать полностью (копирует весь файл)
sudo systemctl edit --full myapp.service

# Убрать изменения (override)
sudo systemctl revert myapp.service
```

---

## 9. Логирование — journalctl

SystemD хранит логи всех сервисов в **systemd journal**.

### Основные команды

```bash
# Логи конкретного сервиса
sudo journalctl -u myapp.service

# Последние 50 строк
sudo journalctl -u myapp.service -n 50

# Follow (как tail -f)
sudo journalctl -u myapp.service -f

# Логи за сегодня
sudo journalctl -u myapp.service --since today

# Логи за последний час
sudo journalctl -u myapp.service --since "1 hour ago"

# Логи с 10:00 до 12:00
sudo journalctl -u myapp.service --since "2025-01-20 10:00:00" --until "2025-01-20 12:00:00"

# Показать ошибки (priority 3 и выше)
sudo journalctl -u myapp.service -p err

# В обратном порядке (новые сверху)
sudo journalctl -u myapp.service -r

# Без пейджера (для скриптов)
sudo journalctl -u myapp.service --no-pager
```

---

### Приоритеты (priority)

| Уровень | Значение | Описание |
|---------|----------|----------|
| 0 | emerg | Система неработоспособна |
| 1 | alert | Нужны срочные действия |
| 2 | crit | Критические условия |
| 3 | err | Ошибки |
| 4 | warning | Предупреждения |
| 5 | notice | Нормально, но важно |
| 6 | info | Информация |
| 7 | debug | Отладка |

**Пример:**

```bash
# Только ошибки и критичнее
sudo journalctl -u myapp.service -p err

# Warning и выше
sudo journalctl -u myapp.service -p warning
```

---

### Управление размером журнала

```bash
# Размер журнала на диске
sudo journalctl --disk-usage

# Очистить старше 7 дней
sudo journalctl --vacuum-time=7d

# Оставить последние 500MB
sudo journalctl --vacuum-size=500M

# Оставить последние 5 файлов
sudo journalctl --vacuum-files=5
```

---

## Таймеры — замена cron

SystemD таймеры — это современная замена cron.

### Преимущества перед cron

- Интеграция с systemd (логи, зависимости)
- Более гибкое планирование
- Автоматический перезапуск при ошибке
- Рандомизация времени запуска

---

## Типичные проблемы

### Проблема 1: Сервис не запускается

**Симптомы:**

```bash
sudo systemctl status myapp.service
# Status: failed
```

**Проверить:**

```bash
# Логи
sudo journalctl -u myapp.service -n 50

# Проверить синтаксис unit файла
systemd-analyze verify /etc/systemd/system/myapp.service
```

**Частые причины:**

- Ошибка в пути `ExecStart`
- Нет прав на запуск
- Неправильный `Type`
- Зависимость не запустилась

---

### Проблема 2: Бесконечный перезапуск

**Симптомы:**

```bash
sudo systemctl status myapp.service
# Restart: Много раз в минуту
```

**Причина:** Сервис падает сразу после запуска.

**Решение:**

1. Посмотреть логи:

```bash
sudo journalctl -u myapp.service -n 100
```

2. Отключить автоперезапуск временно:

```bash
sudo systemctl edit myapp.service
```

Добавить:

```ini
[Service]
Restart=no
```

3. Запустить вручную и отладить

4. После исправления вернуть `Restart=on-failure`

---

### Проблема 3: Сервис не видит переменные окружения

**Причина:** SystemD запускает сервисы с минимальным окружением.

**Решение:**

Явно указать в unit файле:

```ini
[Service]
Environment="PATH=/usr/local/bin:/usr/bin:/bin"
Environment="HOME=/home/myapp"
```

Или использовать `EnvironmentFile`.

---

### Проблема 4: Permission denied

**Симптомы:**

```
Permission denied: '/var/run/myapp.pid'
```

**Решение:**

Создать директорию с правильными правами:

```bash
sudo mkdir -p /var/run/myapp
sudo chown myapp:myapp /var/run/myapp
```

Или в unit файле:

```ini
[Service]
RuntimeDirectory=myapp
RuntimeDirectoryMode=0755
```

SystemD автоматически создаст `/var/run/myapp` с нужными правами.

---

### Проблема 5: Изменения в unit файле не применяются

**Причина:** Забыл сделать `daemon-reload`.

**Решение:**

```bash
sudo systemctl daemon-reload
sudo systemctl restart myapp.service
```

**Запомни:** После ЛЮБЫХ изменений в unit файлах — `daemon-reload`!

---

## Вопросы на собеседованиях

### Вопрос: "Что такое systemd unit?"

**Ответ:** Unit — это конфигурационный файл, описывающий системный ресурс (сервис, таймер, socket и т.д.). Основные типы: .service (сервисы), .timer (таймеры), .socket (сокеты), .target (группы юнитов).

---

### Вопрос: "Из каких секций состоит service unit?"

**Ответ:** Три основные секции:
- `[Unit]` — метаданные и зависимости
- `[Service]` — как запускать процесс
- `[Install]` — как интегрировать в систему (к какому target привязать)

---

### Вопрос: "В чем разница между After и Requires?"

**Ответ:**
- `After` — определяет порядок запуска (ПОСЛЕ чего), но не обязывает
- `Requires` — жесткая зависимость (БЕЗ чего не запустится), но не порядок
- Обычно используют вместе для правильной последовательности и зависимости

---

### Вопрос: "Какие типы сервисов (Type) бывают?"

**Ответ:**
- `simple` — процесс на переднем плане (Node.js, Python)
- `forking` — делает fork, уходит в фон (классические демоны)
- `oneshot` — разовая задача, завершается (скрипты)
- `notify` — уведомляет systemd когда готов (PostgreSQL)

---


---

### Вопрос: "Где создавать свои unit файлы?"

**Ответ:** В `/etc/systemd/system/` — это директория с наивысшим приоритетом. Файлы в `/usr/lib/systemd/system/` — из пакетов, их не нужно редактировать.

---

### Вопрос: "Что делать после изменения unit файла?"

**Ответ:**
```bash
sudo systemctl daemon-reload
sudo systemctl restart myapp.service
```
`daemon-reload` обязателен для применения изменений!

---

### Вопрос: "В чем разница между Wants и Requires?"

**Ответ:**
- `Wants` — мягкая зависимость (попытается запустить, но необязательно)
- `Requires` — жесткая (без нее не запустится, и если она упадет — остановится)

---

## Шпаргалка команд

### Управление сервисами

```bash
systemctl start myapp          # запустить
systemctl stop myapp           # остановить
systemctl restart myapp        # перезапустить
systemctl reload myapp         # перезагрузить конфиг
systemctl status myapp         # статус
systemctl enable myapp         # автозапуск
systemctl disable myapp        # отключить автозапуск
systemctl is-enabled myapp     # проверить автозапуск
```

---

### Просмотр юнитов

```bash
systemctl list-units --type=service              # список сервисов
systemctl list-unit-files --type=service         # все unit файлы
systemctl list-dependencies myapp                # зависимости
systemctl cat myapp                              # содержимое unit
```

---

### Работа с unit файлами

```bash
systemctl daemon-reload                          # перечитать юниты
systemctl edit myapp                             # редактировать (override)
systemctl edit --full myapp                      # редактировать полностью
systemctl revert myapp                           # убрать override
```

---

### Логи (journalctl)

```bash
journalctl -u myapp                              # логи сервиса
journalctl -u myapp -f                           # follow
journalctl -u myapp -n 50                        # последние 50 строк
journalctl -u myapp --since today                # за сегодня
journalctl -u myapp --since "1 hour ago"         # за последний час
journalctl -u myapp -p err                       # только ошибки
journalctl --disk-usage                          # размер журнала
journalctl --vacuum-time=7d                      # очистить старше 7 дней
```

---