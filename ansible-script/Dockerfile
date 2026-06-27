FROM ubuntu:22.04

# Установка переменных окружения для неинтерактивной установки
ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Обновление системы и установка базовых пакетов
RUN apt-get update && apt-get install -y \
    systemd \
    systemd-sysv \
    sudo \
    ssh \
    openssh-server \
    curl \
    wget \
    vim \
    nano \
    git \
    htop \
    net-tools \
    iputils-ping \
    iproute2 \
    dnsutils \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    python3 \
    python3-pip \
    cron \
    rsyslog \
    procps \
    psmisc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Настройка SSH
RUN mkdir /var/run/sshd \
    && echo 'root:password' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Создание пользователя
RUN useradd -m -s /bin/bash -G sudo user \
    && echo 'user:password' | chpasswd \
    && echo 'user ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Настройка systemd
RUN cd /lib/systemd/system/sysinit.target.wants/ \
    && ls | grep -v systemd-tmpfiles-setup | xargs rm -f $1 \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/* \
    && systemctl enable ssh \
    && systemctl enable cron \
    && systemctl enable rsyslog

# Создание директорий для работы
RUN mkdir -p /root/workspace /home/user/workspace \
    && chown -R user:user /home/user/workspace

# Настройка hostname
RUN echo "linux-container" > /etc/hostname

# Добавление приветственного сообщения
RUN echo '#!/bin/bash\necho "================================="\necho "  Linux Container Environment"\necho "  Hostname: $(hostname)"\necho "  User: $(whoami)"\necho "================================="\n' > /etc/profile.d/welcome.sh \
    && chmod +x /etc/profile.d/welcome.sh

VOLUME [ "/sys/fs/cgroup" ]

# Запуск systemd
CMD ["/lib/systemd/systemd"]