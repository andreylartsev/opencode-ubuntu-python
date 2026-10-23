# Используем официальный образ Ubuntu
FROM ubuntu:22.04

# Отключаем интерактивные диалоги во время сборки, фиксируем локаль и таймзону
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=UTC

# Системные утилиты, Python, PostgreSQL, инструменты для документов и зависимости Chrome
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo ca-certificates curl wget git git-lfs openssh-client gnupg \
    bash-completion less vim nano tmux htop tree jq unzip zip \
    ripgrep fd-find bat fzf \
    build-essential pkg-config python3 python3-pip python3-venv python3-dev \
    libpq-dev libssl-dev libffi-dev \
    postgresql-client pspg \
    pandoc graphviz poppler-utils imagemagick \
    texlive-latex-base texlive-latex-recommended texlive-xetex \
    texlive-fonts-recommended texlive-lang-cyrillic lmodern \
    fonts-dejavu-core fonts-liberation fonts-noto-color-emoji \
    libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 libatspi2.0-0 \
    libcups2 libdrm2 libdbus-1-3 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2 libx11-xcb1 libxcb-dri3-0 libxshmfence1 \
    && rm -rf /var/lib/apt/lists/*

# В Ubuntu бинарник fd называется fdfind, делаем привычное имя
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Создаем пользователя opencode с UID/GID 1000:1000 и правами sudo
RUN groupadd -g 1000 opencode && \
    useradd -u 1000 -g opencode -m -s /bin/bash opencode && \
    echo "opencode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/opencode && \
    chmod 0440 /etc/sudoers.d/opencode

# Node.js 22 LTS нужен для mermaid-cli
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# mermaid-cli + Chrome; кэш браузера выносим в /opt, чтобы он был доступен пользователю opencode
ENV PUPPETEER_CACHE_DIR=/opt/puppeteer
RUN npm install -g @mermaid-js/mermaid-cli && \
    printf '{ "args": ["--no-sandbox", "--disable-setuid-sandbox", "--disable-dev-shm-usage"] }\n' > /etc/puppeteer.json && \
    REAL_MMDC="$(readlink -f "$(command -v mmdc)")" && \
    rm -f /usr/local/bin/mmdc && \
    printf '#!/bin/sh\nexec %s -p /etc/puppeteer.json "$@"\n' "$REAL_MMDC" > /usr/local/bin/mmdc && \
    chmod +x /usr/local/bin/mmdc && \
    chown -R opencode:opencode /opt/puppeteer && \
    npm cache clean --force

# uv управляет Python 3.12 и виртуальным окружением с аналитическим стеком
ENV UV_PYTHON_INSTALL_DIR=/opt/uv/python \
    UV_CACHE_DIR=/opt/uv/cache
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh && \
    uv venv /opt/venv --python 3.12 && \
    uv pip install --python /opt/venv/bin/python \
        ipython jupyterlab \
        pandas polars pyarrow duckdb numpy scipy \
        matplotlib seaborn plotly \
        sqlalchemy 'psycopg[binary]' alembic pgcli sqlfluff \
        python-dotenv rich tabulate openpyxl xlsxwriter \
        ruff mypy pytest pytest-cov && \
    chown -R opencode:opencode /opt/uv /opt/venv

# Устанавливаем OpenCode от имени пользователя через явный HOME
RUN curl -fsSL https://opencode.ai/install | HOME=/home/opencode bash && \
    chown -R opencode:opencode /home/opencode

# PATH: сначала виртуальное окружение, затем бинарник OpenCode
ENV HOME=/home/opencode \
    PATH="/opt/venv/bin:/home/opencode/.opencode/bin:${PATH}"

# Создаем рабочую папку для вашего монтирования
RUN mkdir -p /workspace && chown opencode:opencode /workspace

WORKDIR /workspace

USER opencode

# Контейнер запускает утилиту opencode
CMD ["opencode"]
