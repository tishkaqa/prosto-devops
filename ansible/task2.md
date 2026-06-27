# ТЗ

## Структура проекта
```
ansible-roles-practice/
├── inventory/
│   ├── hosts.ini
│   └── group_vars/
│       ├── all.yml
│       ├── webservers.yml
│       └── databases.yml
├── roles/
│   ├── common/
│   ├── postgresql/
├── playbooks/
│   ├── site.yml
│   ├── webservers.yml
│   └── databases.yml
├── ansible.cfg
└── README.md
```

## Роль 1: common

### Назначение
Базовая настройка всех серверов: обновление системы, создание пользователей, настройка SSH, firewall, timezone.

### Структура роли
```
roles/common/
├── tasks/
│   ├── main.yml
│   ├── packages.yml
│   ├── users.yml
│   ├── security.yml
│   └── timezone.yml
├── handlers/
│   └── main.yml
├── templates/
│   └── sshd_config.j2
├── defaults/
│   └── main.yml
└── README.md
```

### Задачи (tasks)

**main.yml:**
- Включать все подзадачи через include_tasks или import_tasks

**packages.yml:**
- Обновить apt cache
- Установить базовые пакеты: curl, wget, vim, htop, git, ufw, python3-pip, ntp

**users.yml:**
- Создать группу `deploy`
- Создать пользователя `deploy` с sudo-правами
- Добавить SSH-ключ для пользователя deploy (из переменной)

**security.yml:**
- Настроить UFW:
  - Разрешить SSH (порт из переменной)
  - Установить default deny incoming
  - Включить UFW
- Скопировать template для sshd_config:
  - Отключить root login
  - Отключить password authentication
  - Изменить порт SSH (если задано в переменных)
- Настроить автоматические security updates

**timezone.yml:**
- Установить timezone (из переменной, по умолчанию UTC)

### Переменные (defaults/main.yml)
```yaml
common_packages:
  - curl
  - wget
  - vim
  - htop
  - git
deploy_user: deploy
deploy_user_groups: deploy,sudo
ssh_port: 22
ssh_disable_root: true
ssh_password_auth: false
timezone: "Europe/Moscow"
```

### Handlers
- restart ssh
- restart ufw

---

## Роль 2: postgresql

### Назначение
Установка и настройка PostgreSQL, создание базы данных и пользователя для приложения.

### Структура роли
```
roles/postgresql/
├── tasks/
│   ├── main.yml
│   ├── install.yml
│   ├── configure.yml
│   └── database.yml
├── handlers/
│   └── main.yml
├── templates/
│   ├── postgresql.conf.j2
│   └── pg_hba.conf.j2
├── defaults/
│   └── main.yml
└── README.md
```

### Задачи (tasks)

**install.yml:**
- Установить PostgreSQL и необходимые пакеты
- Установить python3-psycopg2 (для работы ansible модулей)
- Запустить и включить postgresql service

**configure.yml:**
- Скопировать конфигурационные файлы из templates:
  - postgresql.conf (настроить listen_addresses, max_connections)
  - pg_hba.conf (настроить доступ для app-сервера)
- Уведомить handler для перезагрузки PostgreSQL

**database.yml:**
- Создать базу данных (имя из переменной)
- Создать пользователя БД с паролем
- Выдать права пользователю на базу данных

### Переменные (defaults/main.yml)
```yaml
postgresql_version: "14"
postgresql_listen_addresses: "localhost,{{ ansible_default_ipv4.address }}"
postgresql_max_connections: 100

db_name: myapp_db
db_user: myapp_user
db_password: "{{ vault_db_password }}"  # должен быть в vault
db_host: "{{ ansible_default_ipv4.address }}"
```

### Handlers
- restart postgresql
- reload postgresql

### Дополнительно
- Настроить firewall для доступа к PostgreSQL с app-сервера (порт 5432)
- Создать директорию для бэкапов