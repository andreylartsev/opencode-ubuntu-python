# opencode-ubuntu-python

Docker-образ на базе Ubuntu 22.04 с [OpenCode](https://opencode.ai) и готовым окружением для Python-разработки, работы с PostgreSQL и подготовки аналитических документов со схемами Mermaid.

## Что внутри

- **OpenCode** установлен для пользователя `opencode` (UID/GID `1000:1000`, `sudo` без пароля).
- **Python 3.12** в отдельном venv (`/opt/venv`) под управлением [`uv`](https://docs.astral.sh/uv/).
- **Аналитический стек**: `pandas`, `polars`, `pyarrow`, `duckdb`, `numpy`, `scipy`, `matplotlib`, `seaborn`, `plotly`, `jupyterlab`, `ipython`.
- **PostgreSQL**: `psql`, `pg_dump`, `pg_restore`, `pgcli`, `pspg`, `sqlalchemy`, `psycopg`, `alembic`, `sqlfluff`.
- **Документы**: `pandoc`, `graphviz`, `poppler-utils`, `imagemagick`, TeX Live с `xelatex` и поддержкой кириллицы.
- **Mermaid**: Node.js 22 и `@mermaid-js/mermaid-cli` с локальным Chrome. Команда `mmdc` уже настроена для работы в контейнере.
- **CLI-утилиты**: `git`, `git-lfs`, `ripgrep`, `fd`, `bat`, `fzf`, `jq`, `tmux`, `tree`, `htop`, `vim`, `nano`.

## Сборка

```bash
docker build -f opencode-ubuntu.Dockerfile -t opencode-ubuntu-python .
```

## Запуск

Из корня проекта:

```bash
docker run -it --rm \
  -v "$PWD:/workspace" \
  -v "$PWD/.opencode-data:/home/opencode/.local/share" \
  -p 8888:8888 \
  opencode-ubuntu-python
```

- `/workspace` — рабочая директория с вашим кодом.
- `.opencode-data` — данные и авторизация OpenCode. Директория уже добавлена в `.gitignore`.
- `-p 8888:8888` нужен только для JupyterLab.

Внутри контейнера можно выполнять команды от пользователя `opencode`, а при необходимости устанавливать системные пакеты через `sudo`:

```bash
sudo apt-get update
sudo apt-get install -y <package>
```

## Примеры использования

### Python

```bash
python --version          # Python 3.12
pip install <package>     # установка в /opt/venv
uv pip install <package>  # альтернатива через uv
uv python install 3.13    # дополнительная версия Python
```

### PostgreSQL

```bash
psql "$DATABASE_URL"
pg_dump "$DATABASE_URL" > backup.sql
pgcli "$DATABASE_URL"
```

Если PostgreSQL запущен на хосте, используйте `host.docker.internal` (Linux: `--add-host=host.docker.internal:host-gateway`).

### Mermaid

```bash
mmdc -i diagram.mmd -o diagram.svg
mmdc -i diagram.mmd -o diagram.png
mmdc -i diagram.mmd -o diagram.pdf
```

Команда `mmdc` — это обёртка, которая автоматически передаёт Chrome флаги `--no-sandbox`, `--disable-setuid-sandbox` и `--disable-dev-shm-usage`.

### Документы

```bash
pandoc report.md -o report.pdf \
  --pdf-engine=xelatex \
  -V mainfont="DejaVu Sans" \
  -V lang=ru
```

### JupyterLab

```bash
jupyter lab --ip=0.0.0.0 --no-browser --port 8888
```

После запуска откройте `http://localhost:8888` и используйте токен из вывода команды.

## Примечания

- Образ довольно большой: основную часть занимают TeX Live и Chrome для Mermaid. Если PDF не нужен, можно удалить пакеты `texlive-*`.
- Docker-in-Docker и GPU не настроены.
- Пользователь `opencode` имеет UID/GID `1000`, что обычно совпадает с пользователем хоста и упрощает работу с примонтированными файлами.

## Лицензия

[MIT](LICENSE)
