# Use Python 3.11
ARG BASE_IMAGE="python:3.11-bullseye"
FROM ${BASE_IMAGE}

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=UTF-8 \
    PLAYWRIGHT_BROWSERS_PATH=0 \
    HNSWLIB_NO_NATIVE=1 \
    PATH="/usr/local/bin:$PATH" \
    LD_PRELOAD=libgomp.so.1 \
    LD_LIBRARY_PATH="/usr/local/lib64/:/usr/local/lib" \
    DEBIAN_FRONTEND=noninteractive \
    CHROME_BIN=/usr/bin/chromium \
    CHROMIUM_PATH=/usr/bin/chromium \
    CHROMIUM_FLAGS="--no-sandbox"

# Install system packages
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    apt-get update --fix-missing && \
    apt-get upgrade -y && \
    curl -sL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --fix-missing --no-install-recommends \
    git build-essential gcc g++ sqlite3 libsqlite3-dev wget libgomp1 ffmpeg \
    python3 python3-pip python3-dev curl postgresql-client libnss3 libnspr4 \
    libatk1.0-0 libatk-bridge2.0-0 libcups2 libatspi2.0-0 libxcomposite1 nodejs \
    libportaudio2 libasound-dev libreoffice unoconv poppler-utils chromium chromium-sandbox \
    unixodbc unixodbc-dev cmake openscad xvfb xauth \
    libdbus-1-3 libxkbcommon0 libxdamage1 \
    libxfixes3 libxrandr2 libgbm1 libasound2 \
    pandoc texlive-latex-extra lmodern bubblewrap && \
    apt-get install -y gcc-10 g++-10 && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10 && \
    awk '/^deb / && !seen[$0]++ {gsub(/^deb /, "deb-src "); print}' /etc/apt/sources.list | tee -a /etc/apt/sources.list && \
    apt-get update && \
    apt-get build-dep sqlite3 -y && \
    curl -LsSf https://astral.sh/uv/install.sh | sh && \
    rm -rf /var/lib/apt/lists/*
ENV PATH="/root/.local/bin:$PATH"

# Install Python runtime and essential tools
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip install --no-cache-dir --upgrade pip setuptools

# Set work directory
WORKDIR /app

COPY static-requirements.txt /app/static-requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip install --no-cache-dir -r static-requirements.txt && \
    playwright install chromium

COPY requirements.txt /app/requirements.txt
RUN --mount=type=cache,target=/root/.cache/pip,sharing=locked \
    pip install --no-cache-dir -r requirements.txt && \
    python -m spacy download en_core_web_sm
