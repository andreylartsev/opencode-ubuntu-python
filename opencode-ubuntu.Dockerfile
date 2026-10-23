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

# Создаем пользователя opencode с UID/GID 1000:1000
RUN groupadd -g 1000 opencode && \
    useradd -u 1000 -g opencode -m -s /bin/bash opencode && \
    echo "opencode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Устанавливаем OpenCode
RUN curl -fsSL https://opencode.ai/install | bash

# Заранее создаем папку /workspace и даем на неё права пользователю opencode.
# Это важно, так как при монтировании -v папки хоста Docker может инициализировать её под root,
# если она не существует.
RUN mkdir /workspace && chown opencode:opencode /workspace

# Назначаем рабочую директорию, куда вы монтируете код проекта ($PWD)
WORKDIR /workspace

# Контейнер запускает утилиту opencode
CMD ["opencode"]
