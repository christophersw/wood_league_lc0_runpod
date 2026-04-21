FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LC0_NETWORK=/usr/local/share/lc0-network.pb.gz

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        meson \
        ninja-build \
        build-essential \
        libopenblas-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --recurse-submodules https://github.com/LeelaChessZero/lc0.git /tmp/lc0 \
    && cd /tmp/lc0 \
    && ./build.sh \
    && cp build/release/lc0 /usr/local/bin/lc0 \
    && chmod +x /usr/local/bin/lc0 \
    && rm -rf /tmp/lc0

ENV LC0_PATH=/usr/local/bin/lc0

RUN curl --connect-timeout 10 --max-time 60 -fsSL "https://storage.lczero.org/files/networks-contrib/t1-512x15x8h-distilled-swa-3395000.pb.gz" \
    -o /usr/local/share/lc0-network.pb.gz || true

COPY pyproject.toml README.md ./
COPY lc0_worker ./lc0_worker
COPY handler.py ./

RUN pip install --no-cache-dir .

CMD ["python", "handler.py"]
