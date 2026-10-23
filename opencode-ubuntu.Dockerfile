# Используем официальный образ Ubuntu
FROM ubuntu:22.04

# Отключаем интерактивные диалоги во время сборки
ENV DEBIAN_FRONTEND=noninteractive

# Устанавливаем системные утилиты, sudo и Python
RUN apt-get update && apt-get install -y \
    sudo \
    python3 \
    python3-pip \
    curl \
    git \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Создаем пользователя opencode с UID/GID 1000:1000 и правами sudo
RUN groupadd -g 1000 opencode && \
    useradd -u 1000 -g opencode -m -s /bin/bash opencode && \
    echo "opencode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Скачиваем скрипт и запускаем установку, явно передавая домашнюю директорию пользователя 1000:1000
# Это гарантирует правильную установку путей без конфликтов прав
RUN curl -fsSL https://opencode.ai/install | HOME=/home/opencode bash

# Убеждаемся, что все файлы внутри домашней папки принадлежат пользователю opencode
RUN chown -R opencode:opencode /home/opencode

# Добавляем путь к бинарнику пользователя в глобальный PATH
ENV PATH="/home/opencode/.opencode/bin:${PATH}"

# Создаем рабочую папку для вашего монтирования
RUN mkdir /workspace && chown opencode:opencode /workspace
WORKDIR /workspace

# Контейнер запускает утилиту opencode
CMD ["opencode"]
