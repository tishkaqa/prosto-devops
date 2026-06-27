# ТЗ

## Структура проекта
```
gitlab-ci-practice/
├── pipeline-1-webapp/
│   ├── src/
│   │   ├── app.py (или index.js)
│   │   └── templates/
│   ├── tests/
│   │   └── test_app.py
│   ├── Dockerfile
│   ├── requirements.txt (или package.json)
│   ├── .gitlab-ci.yml
│   └── README.md
├── pipeline-2-microservices/
│   ├── frontend/
│   │   ├── src/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── backend/
│   │   ├── app/
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── docker-compose.yml
│   ├── .gitlab-ci.yml
│   └── README.md
└── README.md
```

---

# Пайплайн 1: Веб-приложение (базовый уровень)

## Описание
Создать CI/CD пайплайн для простого веб-приложения (Flask/Express), который будет собирать образ, запускать тесты, пушить в Registry и деплоить на сервер.

## Структура приложения
```
pipeline-1-webapp/
├── src/
│   ├── app.py (Flask) или index.js (Express)
│   └── templates/
│       └── index.html
├── tests/
│   └── test_app.py (или test_app.js)
├── Dockerfile
├── requirements.txt (или package.json)
├── .gitlab-ci.yml
└── README.md
```

---

## Этап 1: Подготовка приложения

### Задачи

**1. Создать простое веб-приложение:**
- **Flask (Python)**: REST API с endpoints:
  - `GET /` - главная страница (отдает HTML)
  - `GET /health` - health check (возвращает статус и версию)
  - `GET /api/info` - информация о приложении (версия, environment)
- **Express (Node.js)**: аналогичные endpoints
- Приложение должно читать переменные окружения:
  - `APP_VERSION` - версия приложения
  - `ENVIRONMENT` - окружение (dev/staging/prod)
  - `PORT` - порт для запуска (по умолчанию 5000 или 3000)

**2. Написать Dockerfile:**
- Использовать multi-stage build (если нужно)
- Базовый образ: python:3.11-slim или node:18-alpine
- Установить зависимости
- Скопировать исходники
- Создать non-root пользователя
- Expose порт приложения
- CMD для запуска приложения

**3. Написать unit-тесты:**
- Минимум 3 теста:
  - Тест на доступность главной страницы (статус 200)
  - Тест на health endpoint
  - Тест на корректность возврата версии
- Использовать pytest (Python) или jest (Node.js)
- Тесты должны успешно проходить локально

**4. Создать requirements.txt (Python) или package.json (Node.js):**
- Указать все зависимости приложения
- Указать зависимости для тестирования (в devDependencies для Node.js)

### Требования к приложению
- Приложение должно запускаться локально
- Все тесты должны проходить
- Docker образ должен собираться без ошибок
- Размер образа < 150MB

---

## Этап 2: Настройка GitLab проекта

### Задачи

**1. Создать новый проект в GitLab:**
- Название: `pipeline-1-webapp`
- Visibility: Private
- Initialize with README

**2. Настроить переменные окружения (Settings → CI/CD → Variables):**
- `CI_REGISTRY_USER` - username для Container Registry (тип: default)
- `CI_REGISTRY_PASSWORD` - password для Registry (тип: masked)
- `SSH_PRIVATE_KEY` - приватный SSH ключ для деплоя на сервер (тип: file)
- `DEPLOY_SERVER` - IP адрес или hostname сервера для деплоя (например: `192.168.1.100`)
- `DEPLOY_USER` - пользователь для SSH подключения (например: `deploy`)
- `APP_VERSION` - версия приложения (например: `1.0.0`)

**3. Включить Container Registry:**
- Проверить что Registry включен в проекте
- Проверить доступность: `gitlab.prostodevops.ru:5050/<username>/<project>`

**4. Настроить GitLab Runner:**
- Убедиться что в проекте доступен shared runner
- Проверить теги runner'а (должен быть docker executor)
- Если нужно, зарегистрировать специфичный runner для проекта

**5. Добавить SSH ключ на целевой сервер:**
- Сгенерировать SSH ключ: `ssh-keygen -t ed25519 -C "gitlab-ci"`
- Добавить публичный ключ на сервер в `~/.ssh/authorized_keys`
- Приватный ключ добавить в GitLab переменные

---

## Этап 3: Создание .gitlab-ci.yml

### Задачи

**1. Определить стейджи пайплайна:**
```yaml
stages:
  - lint
  - test
  - build
  - push
  - deploy
```

**2. Написать job для линтинга (stage: lint):**
- Название: `lint-code`
- Образ: python:3.11 или node:18
- Установить линтер (flake8 для Python, eslint для Node.js)
- Запустить проверку кода
- Сохранить отчет как artifact
- Выполнять на любом commit

**3. Написать job для запуска тестов (stage: test):**
- Название: `run-tests`
- Образ: python:3.11-slim или node:18-alpine
- Установить зависимости
- Запустить тесты: `pytest` или `npm test`
- Создать coverage report
- Сохранить отчеты как artifacts
- Выполнять на любом commit
- Использовать cache для зависимостей

**4. Написать job для сборки Docker образа (stage: build):**
- Название: `build-image`
- Образ: docker:latest
- Services: docker:dind
- Собрать образ с тегом: `$CI_COMMIT_SHORT_SHA`
- Не пушить образ (только собрать для проверки)
- Использовать cache для Docker layers (если возможно)
- Выполнять на любом commit

**5. Написать job для пуша образа в Registry (stage: push):**
- Название: `push-image`
- Образ: docker:latest
- Services: docker:dind
- Залогиниться в Container Registry
- Собрать образ с тегами:
  - `latest`
  - `$CI_COMMIT_SHORT_SHA`
  - `$CI_COMMIT_TAG` (если это tag)
- Запушить все теги в Registry
- Выполнять только на ветках `main` или `develop`
- Должен зависеть от успешного прохождения тестов

**6. Написать job для деплоя на DEV сервер (stage: deploy):**
- Название: `deploy-dev`
- Образ: alpine:latest
- Установить openssh-client и docker-cli (через apk)
- Настроить SSH:
  - Добавить приватный ключ из переменной `$SSH_PRIVATE_KEY`
  - Настроить `~/.ssh/config` для подключения
  - Отключить StrictHostKeyChecking (для CI/CD)
- Подключиться к серверу по SSH
- Выполнить команды на сервере:
  - Залогиниться в Registry
  - Остановить и удалить старый контейнер (если есть)
  - Запустить новый контейнер из свежего образа
  - Проверить что контейнер запустился
- Environment: development
- Выполнять автоматически при push в `develop`
- URL: адрес приложения на dev сервере

**7. Написать job для деплоя на PROD сервер (stage: deploy):**
- Название: `deploy-prod`
- Аналогично `deploy-dev`, но:
  - Environment: production
  - `when: manual` - требует ручного подтверждения
  - Выполнять только при push в `main` или при создании tag
  - Использовать стабильный тег образа (не latest)
- URL: адрес приложения на prod сервере


### Пример структуры job
```yaml
lint-code:
  stage: lint
  image: python:3.11
  before_script:
    - pip install flake8
  script:
    - flake8 src/
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push"'
```

---

## Этап 4: Проверка работы пайплайна

### Задачи

**1. Протестировать пайплайн на feature ветке:**
- Создать новую ветку: `git checkout -b feature/test-pipeline`
- Добавить .gitlab-ci.yml
- Закоммитить и запушить
- Проверить что запустились только stages: lint, test, build
- Убедиться что deploy не запускается

**2. Проверить прохождение всех stages:**
- Открыть CI/CD → Pipelines в GitLab
- Посмотреть логи каждого job
- Убедиться что:
  - Линтинг прошел успешно
  - Тесты прошли с coverage отчетом
  - Образ собрался без ошибок
  - Артефакты сохранились

**3. Протестировать пуш образа:**
- Смержить feature ветку в `develop`
- Проверить что запустился stage `push`
- Проверить что образ появился в Container Registry
- Проверить теги образа: `latest` и `$CI_COMMIT_SHORT_SHA`

**4. Протестировать автоматический деплой на DEV:**
- После успешного пуша образа должен запуститься deploy-dev
- Проверить логи деплоя
- Зайти на сервер и проверить что контейнер запущен:
  ```bash
  docker ps | grep webapp
  curl http://localhost:5000/health
  ```

**5. Протестировать ручной деплой на PROD:**
- Смержить `develop` в `main`
- Проверить что job `deploy-prod` требует ручного запуска
- Нажать кнопку "Play" для запуска деплоя
- Проверить что приложение задеплоилось на prod сервер
- Проверить доступность приложения

**6. Протестировать деплой по тегу:**
- Создать git tag: `git tag v1.0.0`
- Запушить тег: `git push origin v1.0.0`
- Проверить что pipeline собрал образ с тегом `v1.0.0`
- Проверить что можно задеплоить этот тег в production

**7. Проверить откат:**
- Задеплоить приложение версии v1.0.0
- Создать v1.0.1 с изменениями
- Задеплоить v1.0.1
- Вручную запустить контейнер с образом v1.0.0 для отката
- Убедиться что откат работает

---

# Пайплайн 2: Микросервисы (продвинутый уровень)

## Структура проекта
```
pipeline-2-microservices/
├── frontend/
│   ├── src/
│   │   └── App.jsx
│   ├── public/
│   ├── Dockerfile
│   ├── nginx.conf
│   ├── package.json
│   └── .env.example
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py
│   │   └── routes.py
│   ├── tests/
│   │   └── test_api.py
│   ├── Dockerfile
│   ├── requirements.txt
│   └── .env.example
├── docker-compose.yml
├── docker-compose.test.yml
├── .gitlab-ci.yml
└── README.md
```

---

## Этап 1: Подготовка микросервисов

### Задачи

**1. Создать Backend API (Python Flask/FastAPI) (нагенерить):**
- REST API с endpoints:
  - `GET /api/health` - health check
  - `GET /api/users` - получить список пользователей (из БД или mock)
  - `POST /api/users` - создать пользователя
  - `GET /api/stats` - статистика приложения
- Подключение к PostgreSQL через переменные окружения
- Логирование всех запросов
- CORS для доступа с frontend

**2. Создать Frontend (React/Vue) (нагенерить):**
- SPA приложение с:
  - Главной страницей со списком пользователей
  - Формой для добавления пользователя
  - Отображением статистики
  - Индикатором подключения к API
- Использовать переменную окружения `REACT_APP_API_URL` для адреса backend
- Стили: Bootstrap или Tailwind CSS

**3. Написать Dockerfile для Backend:**
- Базовый образ: python:3.11-slim
- Установить зависимости из requirements.txt
- Скопировать код приложения
- Non-root пользователь
- Health check: `curl http://localhost:5000/api/health`
- Expose порт 5000
- CMD для запуска через gunicorn или uvicorn

**4. Написать Dockerfile для Frontend:**
- Multi-stage build:
  - Build stage: node:18 - сборка production build
  - Production stage: nginx:alpine - раздача статики
- Скопировать nginx.conf для корректной работы SPA
- Использовать build args для передачи API_URL
- Expose порт 80

**5. Создать docker-compose.yml для локальной разработки:**
- Services:
  - `frontend` - frontend приложение (порт 3000)
  - `backend` - backend API (порт 5000)
  - `postgres` - PostgreSQL база данных (порт 5432)
- Networks: создать общую сеть для всех сервисов
- Volumes: для постоянного хранения данных postgres
- Environment variables: для настройки подключений

---

## Этап 2: Настройка GitLab проекта

### Задачи

**1. Создать новый проект в GitLab:**
- Название: `pipeline-2-microservices`
- Visibility: Private
- Initialize with README

**2. Настроить переменные окружения (Settings → CI/CD → Variables):**
- `CI_REGISTRY_USER` - username для Container Registry
- `CI_REGISTRY_PASSWORD` - password для Registry (masked)
- `SSH_PRIVATE_KEY` - SSH ключ для деплоя (file)
- `DEPLOY_SERVER` - адрес сервера для деплоя
- `DEPLOY_USER` - пользователь для SSH
- `POSTGRES_PASSWORD` - пароль для PostgreSQL (masked)
- `API_URL_DEV` - URL backend API для dev (например: `http://api-dev.devops.ru`)
- `API_URL_PROD` - URL backend API для prod
- `FRONTEND_URL_DEV` - URL frontend для dev
- `FRONTEND_URL_PROD` - URL frontend для prod

**3. Включить Container Registry:**
- Проверить доступность Registry для проекта

**4. Настроить Protected Branches:**
- Защитить ветку `main` - разрешить пуш только maintainers
- Настроить Merge Request approvals (если нужно)

---

## Этап 3: Создание .gitlab-ci.yml

### Задачи

**1. Определить stages пайплайна:**
```yaml
stages:
  - lint
  - test
  - build
  - integration-test
  - push
  - deploy
```

**2. Написать job для линтинга Backend (stage: lint):**
- Название: `lint-backend`
- Проверка кода через flake8 или pylint
- Выполнять при изменениях в `backend/**`
- Сохранять отчет как artifact

**3. Написать job для линтинга Frontend (stage: lint):**
- Название: `lint-frontend`
- Проверка кода через eslint
- Выполнять при изменениях в `frontend/**`
- Сохранять отчет как artifact

**4. Написать job для тестирования Backend (stage: test):**
- Название: `test-backend`
- Запустить unit tests через pytest
- Создать coverage report
- Сохранить test results (JUnit XML format)
- Использовать cache для pip зависимостей
- Выполнять при изменениях в `backend/**`

**5. Написать job для тестирования Frontend (stage: test):**
- Название: `test-frontend`
- Запустить tests через jest
- Создать coverage report
- Использовать cache для node_modules
- Выполнять при изменениях в `frontend/**`

**6. Написать job для сборки Backend образа (stage: build):**
- Название: `build-backend`
- Собрать Docker образ для backend
- Тег: `$CI_REGISTRY_IMAGE/backend:$CI_COMMIT_SHORT_SHA`
- Использовать Docker layer caching
- Выполнять при изменениях в `backend/**` или на `main`/`develop`

**7. Написать job для сборки Frontend образа (stage: build):**
- Название: `build-frontend`
- Собрать Docker образ для frontend
- Передать build arg `API_URL` в зависимости от окружения
- Тег: `$CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHORT_SHA`
- Выполнять при изменениях в `frontend/**` или на `main`/`develop`

**8. Написать job для интеграционных тестов (stage: integration-test):**
- Название: `integration-tests`
- Использовать docker-compose.test.yml
- Запустить все сервисы (frontend, backend, postgres)
- Дождаться готовности сервисов
- Выполнить интеграционные тесты:
  - Проверить доступность frontend
  - Проверить доступность backend API
  - Проверить что frontend может обращаться к backend
  - Проверить CRUD операции через API
- Собрать логи всех сервисов при ошибке
- Сохранить логи как artifacts
- Остановить и удалить контейнеры после тестов
- Выполнять только если оба образа собрались

**9. Написать job для пуша образов в Registry (stage: push):**
- Название: `push-images`
- Залогиниться в Registry
- Запушить backend образ с тегами:
  - `latest`
  - `$CI_COMMIT_SHORT_SHA`
  - `$CI_COMMIT_TAG` (если tag)
- Запушить frontend образ с теми же тегами
- Выполнять только на `main` и `develop`
- Зависит от успешного прохождения integration-tests

**10. Написать job для деплоя на DEV (stage: deploy):**
- Название: `deploy-dev`
- Подключиться к серверу по SSH
- Скопировать docker-compose.yml на сервер (через scp или heredoc)
- Обновить .env файл с переменными для dev
- Выполнить на сервере:
  ```bash
  docker-compose pull
  docker-compose down
  docker-compose up -d
  ```
- Дождаться запуска всех контейнеров
- Выполнить health check всех сервисов
- Environment: development
- Выполнять автоматически на `develop`

**11. Написать job для деплоя на PROD (stage: deploy):**
- Название: `deploy-prod`
- Аналогично deploy-dev, но:
  - Использовать prod переменные окружения
  - Использовать конкретный тег образа (не latest)
  - `when: manual` - требует подтверждения
  - Добавить smoke tests после деплоя
  - Environment: production
- Выполнять на `main` или при создании tag

### Дополнительные требования

**Использовать параллельное выполнение:**
- Линтинг backend и frontend параллельно
- Тестирование backend и frontend параллельно
- Сборка backend и frontend параллельно

**Использовать dependencies между jobs:**
- Integration tests зависят от обоих build jobs
- Push зависит от integration tests
- Deploy зависит от push

**Использовать правила выполнения (rules):**
- Умные правила для выполнения только при изменениях в соответствующих директориях
- Использовать `changes:` для отслеживания изменений
- Комбинировать с условиями на ветки

**Настроить retry для нестабильных jobs:**
- Integration tests: retry 2 раза при ошибке
- Deploy jobs: retry 1 раз при ошибке сети

**Использовать расширенные возможности artifacts:**
- Передавать собранные образы между stages через artifacts (если возможно)
- Expire artifacts через 7 дней
- Разные artifacts для разных jobs

**Добавить динамические environments:**
- Автоматически создавать review apps для merge requests
- Каждая ветка получает свой уникальный URL
- Автоматически удалять environment при закрытии MR

### Пример структуры сложного job
```yaml
integration-tests:
  stage: integration-test
  image: docker/compose:latest
  services:
    - docker:dind
  variables:
    DOCKER_HOST: tcp://docker:2375
    DOCKER_TLS_CERTDIR: ""
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker-compose -f docker-compose.test.yml pull
    - docker-compose -f docker-compose.test.yml up -d
    - docker-compose -f docker-compose.test.yml exec -T backend pytest
    - docker-compose -f docker-compose.test.yml logs
  after_script:
    - docker-compose -f docker-compose.test.yml down -v
  dependencies:
    - build-backend
    - build-frontend
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH == "main" || $CI_COMMIT_BRANCH == "develop"'
```

---

## Этап 4: Проверка работы пайплайна

### Задачи

**1. Протестировать параллельное выполнение:**
- Создать MR с изменениями в обоих сервисах
- Проверить что lint и test jobs запускаются параллельно
- Проверить что build jobs тоже параллельны
- Убедиться что время выполнения пайплайна оптимизировано

**2. Протестировать умные rules:**
- Изменить только backend код
- Проверить что frontend jobs не запустились
- Изменить только frontend код
- Проверить что backend jobs не запустились

**3. Протестировать интеграционные тесты:**
- Запушить изменения в оба сервиса
- Дождаться stage integration-test
- Проверить логи: должны быть логи всех сервисов
- Убедиться что тесты проверяют взаимодействие между сервисами

**4. Протестировать деплой на DEV:**
- Смержить в develop
- Дождаться автоматического деплоя
- Проверить на сервере:
  ```bash
  docker-compose ps
  curl http://api-dev.prostodevops.ru/api/health
  curl http://app-dev.prostodevops.ru
  ```
- Проверить что оба сервиса работают и взаимодействуют

**5. Протестировать деплой на PROD:**
- Создать release tag: `v1.0.0`
- Проверить что собрались образы с этим тегом
- Запустить ручной deploy-prod
- Проверить что на prod развернулась именно версия v1.0.0
- Выполнить smoke tests

**6. Протестировать откат:**
- Задеплоить v1.0.1 с багом
- Выявить проблему
- Вручную откатиться на v1.0.0:
  ```bash
  # На сервере
  docker-compose down
  # Изменить теги в .env на v1.0.0
  docker-compose up -d
  ```

**7. Протестировать review apps (если настроены):**
- Создать MR из feature ветки
- Проверить что создался динамический environment
- Проверить доступность review app по уникальному URL
- Закрыть MR - убедиться что environment удалился

**8. Проверить artifacts и reports:**
- Открыть любой завершенный пайплайн
- Скачать test reports
- Проверить coverage reports
- Посмотреть JUnit XML для интеграции с GitLab Test Results

**9. Проверить Pipeline Graphs:**
- Открыть CI/CD → Pipelines → выбрать pipeline
- Посмотреть граф зависимостей между jobs
- Убедиться что структура логичная и оптимальная

**10. Проверить производительность:**
- Сравнить время выполнения с параллелизацией и без
- Проверить эффективность cache
- Оптимизировать медленные jobs
