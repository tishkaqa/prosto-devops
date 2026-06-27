# ТЗ

## Цель работы
Развернуть full-stack приложение (frontend + backend + database) в Kubernetes кластере с использованием GitLab CI/CD, Helm charts и Container Registry. Настроить автоматический деплой через пайп.

## Архитектура приложения
- **Frontend**
- **Backend**
- **Database**: PostgreSQL
- **Инфраструктура**: 
  - GitLab: `gitlab.prostodevops.ru`
  - Kubernetes: доступ через Rancher `k8s.prostodevops.ru`
  - Container Registry: `gitlab.prostodevops.ru`

---

## Структура проекта
```
fullstack-app/
├── frontend/
│   ├── src/
│   ├── Dockerfile
│   └── nginx.conf
├── backend/
│   ├── app/
│   ├── requirements.txt (или package.json)
│   └── Dockerfile
├── helm/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── _helpers.tpl
│       ├── frontend-deployment.yaml
│       ├── frontend-service.yaml
│       ├── backend-deployment.yaml
│       ├── backend-service.yaml
│       ├── postgres-statefulset.yaml
│       ├── postgres-service.yaml
│       ├── postgres-pvc.yaml
│       ├── configmap.yaml
│       ├── secrets.yaml
│       └── ingress.yaml
├── .gitlab-ci.yml
├── k8s/
│   └── namespace.yaml
└── README.md
```

---

## Этап 1: Настройка GitLab Container Registry

### Задачи

1. **Настроить аутентификацию в Registry**:
   - Создать Deploy Token в настройках GitLab проекта (Settings → Repository → Deploy Tokens)
   - Указать права: read_registry, write_registry
   - Сохранить username и token (они нужны для CI/CD и Kubernetes)
   - Протестировать вход: `docker login gitlab.prostodevops.ru:5050 -u <deploy-token-user> -p <deploy-token>`

2. **Создать Kubernetes Secret для pull образов**:
   - В кластере создать namespace для приложения
   - Создать Secret типа `docker-registry` с credentials от GitLab Registry
   - Назвать Secret: `gitlab-registry-secret`
   - Этот Secret будет использоваться в imagePullSecrets в Deployment'ах

3. **Протестировать push образа в Registry**:
   - Собрать тестовый образ локально
   - Залогиниться в Registry
   - Запушить образ с тегом: `gitlab.prostodevops.ru:5050/<username>/<project>/frontend:test`
   - Проверить что образ появился в GitLab 

### Команды для проверки
```bash
# Логин в Registry
docker login gitlab.prostodevops.ru:5050

# Build и push
docker build -t gitlab.prostodevops.ru:5050/myuser/myproject/frontend:v1.0 ./frontend
docker push gitlab.prostodevops.ru:5050/myuser/myproject/frontend:v1.0

# Создание Secret в Kubernetes
kubectl create secret docker-registry gitlab-registry-secret \
  --docker-server=gitlab.prostodevops.ru:5050 \
  --docker-username=<deploy-token-user> \
  --docker-password=<deploy-token> \
  --namespace=fullstack-app
```

---

## Этап 2: Написание Helm Charts

### Задачи

**1. Создать базовую структуру Helm chart:**
- Создать директорию `helm/` в корне проекта
- Создать файл `Chart.yaml` с метаданными (name, version, appVersion, description)
- Создать директорию `templates/` для манифестов Kubernetes
- Создать файл `values.yaml` с дефолтными значениями

**2. Описать values.yaml с основными параметрами:**
- Настройки namespace
- Настройки registry (адрес, imagePullSecrets)
- Для каждого компонента (frontend, backend, postgres):
  - Имя сервиса
  - Количество реплик
  - Docker образ (repository, tag, pullPolicy)
  - Service (type, port, targetPort)
  - Resources (requests и limits для CPU/Memory)
  - Переменные окружения
- Настройки Ingress (enabled, host, path, TLS)
- Настройки storage для PostgreSQL (size, storageClass)

**3. Написать templates для Frontend:**
- `frontend-deployment.yaml`:
  - Deployment с указанным количеством реплик
  - Использовать значения из values.yaml (image, resources, env)
  - Добавить imagePullSecrets для доступа к Registry
  - Настроить livenessProbe и readinessProbe (проверка доступности на порту 80)
  - Пробросить переменную API_URL для подключения к backend
- `frontend-service.yaml`:
  - Service типа ClusterIP
  - Selector по labels приложения
  - Пробросить порт 80

**4. Написать templates для Backend:**
- `backend-deployment.yaml`:
  - Deployment с указанным количеством реплик
  - Пробросить переменные окружения
  - Настроить health checks на endpoint `/api/health`
  - Добавить imagePullSecrets
  - Указать resources (requests/limits)
- `backend-service.yaml`:
  - Service типа ClusterIP
  - Порт 5000 (или другой, если используете Node.js)

**5. Написать templates для PostgreSQL:**
- `postgres-statefulset.yaml`:
  - StatefulSet с 1 репликой
  - Использовать образ postgres:15-alpine
  - Пробросить переменные: POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD (из Secret)
  - Добавить PGDATA переменную для указания пути к данным
  - Примонтировать PersistentVolume к /var/lib/postgresql/data
  - Указать volumeClaimTemplate для автоматического создания PVC
- `postgres-service.yaml`:
  - Service типа ClusterIP
  - Порт 5432
  - Headless service (clusterIP: None) для StatefulSet
- `postgres-pvc.yaml` (опционально, если не используете volumeClaimTemplate):
  - PersistentVolumeClaim с указанным размером хранилища
  - storageClass (например, standard или custom)

**6. Создать дополнительные манифесты:**
- `secrets.yaml`:
  - Secret с паролем для PostgreSQL
  - Secret с DATABASE_URL для backend
  - Использовать base64 encoding для значений
  - Либо использовать stringData для автоматического кодирования
- `configmap.yaml` (опционально):
  - ConfigMap с настройками приложения (если есть конфиги)
- `ingress.yaml`:
  - Ingress для доступа к приложению извне
  - Указать правила маршрутизации:
    - `/` → frontend service
    - `/api` → backend service
  - Настроить TLS (если нужен HTTPS)
  - Добавить annotations для ingress-контроллера

**7. Создать helper файл `_helpers.tpl`:**
- Добавить template для генерации labels
- Добавить template для имени приложения
- Использовать эти helpers в манифестах для консистентности

### Требования к Helm charts
- Все параметры должны быть параметризированы через values.yaml
- Использовать функции Helm (toYaml, quote, nindent) для корректного форматирования
- Добавить labels и annotations для мониторинга
- Helm chart должен проходить валидацию: `helm lint ./helm`
- Возможность установки с разными values: `helm install -f values-dev.yaml`

---

## Этап 3: Подключение к Kubernetes через Rancher

### Задачи
1. **Получить доступ к кластеру через Rancher**:
   - Зайти в Rancher UI по адресу `k8s.prostodevops.ru`
   - Выбрать нужный кластер
   - Скачать kubeconfig файл (через кнопку в правом верхнем углу)

2. **Создать Secret для Registry в namespace**:
   - Использовать Deploy Token от GitLab
   - Создать Secret типа docker-registry
   - Проверить что Secret создан

---

## Этап 4: Создание GitLab CI/CD Pipeline

### Задачи

**1. Создать файл `.gitlab-ci.yml` в корне проекта**

**2. Определить стейджи пайпа:**
```yaml
stages:
  - build
  - test
  - deploy
```

**3. Настроить переменные окружения в GitLab**:
- В Settings → CI/CD → Variables добавить:
  - `CI_REGISTRY_USER` - username от Deploy Token
  - `CI_REGISTRY_PASSWORD` - password от Deploy Token (тип: masked)
  - `KUBE_CONFIG` - содержимое kubeconfig файла (тип: file)
  - `POSTGRES_PASSWORD` - пароль для PostgreSQL (тип: masked)

**4. Написать job для сборки Frontend:**
- Stage: build
- Использовать Docker-in-Docker (dind) или kaniko
- Залогиниться в Container Registry
- Собрать образ из `./frontend/Dockerfile`
- Пометить образ тегами: `latest` и `$CI_COMMIT_SHORT_SHA`
- Запушить образы в Registry
- Выполнять только при изменениях в директории `frontend/` (rules)

**5. Написать job для сборки Backend:**
- Stage: build
- Аналогично frontend, но для `./backend/`
- Собрать и запушить образ backend
- Использовать теги: `latest` и `$CI_COMMIT_SHORT_SHA`
- Выполнять только при изменениях в директории `backend/`

**6. Написать job для тестирования (опционально):**
- Stage: test
- Запустить линтеры для кода
- Запустить unit-тесты для backend
- Проверить Helm chart: `helm lint ./helm`
- Проверить манифесты: `helm template ./helm | kubectl apply --dry-run=client -f -`

**7. Написать job для деплоя:**
- Stage: deploy
- Установить kubectl и helm
- Настроить kubeconfig из переменной `$KUBE_CONFIG`
- Обновить или установить Helm release:
  ```bash
  helm upgrade --install myapp ./helm \
    --namespace fullstack-app \
    --create-namespace \
    --values ./helm/values-dev.yaml \
    --set frontend.image.tag=$CI_COMMIT_SHORT_SHA \
    --set backend.image.tag=$CI_COMMIT_SHORT_SHA \
    --set postgresql.password=$POSTGRES_PASSWORD
  ```
- Выполнять автоматически при push в ветку `develop`
- Дождаться готовности deployment: `kubectl rollout status deployment/frontend -n fullstack-app`


### Пример структуры job
```yaml
build_frontend:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - cd frontend
    - docker build -t $CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHORT_SHA .
    - docker push $CI_REGISTRY_IMAGE/frontend:$CI_COMMIT_SHORT_SHA
  rules:
    - changes:
        - frontend/**/*
```