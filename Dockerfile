# ── Stage 1: build lc0 from source against CUDA 12.8 ─────────────────────────
# No Linux pre-built lc0 binary exists — all release assets are Windows/Android.
# CUDA 12.8 devel image required for the nvcc compiler.
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        meson \
        ninja-build \
        build-essential \
        libopenblas-dev \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Build lc0 v0.32.1 with CUDA/cuDNN backend. PTX forward-compatibility means the
# resulting binary will JIT-compile for sm_120 (Blackwell / RTX 5090) via the CUDA
# 12.8 driver.
RUN git clone --branch v0.32.1 --depth 1 --recurse-submodules https://github.com/LeelaChessZero/lc0.git /tmp/lc0 \
    && cd /tmp/lc0 \
    && ./build.sh -Dbackends=cuda \
    && cp build/release/lc0 /usr/local/bin/lc0 \
    && chmod +x /usr/local/bin/lc0 \
    && rm -rf /tmp/lc0

# ── Stage 2: slim runtime image ───────────────────────────────────────────────
# cudnn-runtime ships only the CUDA + cuDNN shared libs needed to run lc0.
FROM nvidia/cuda:12.8.1-cudnn-runtime-ubuntu22.04

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LC0_NETWORK=/usr/local/share/lc0-network.pb.gz \
    LC0_PATH=/usr/local/bin/lc0 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-venv \
        python3-pip \
        curl \
        libopenblas0 \
        zlib1g \
    && ln -sf /usr/bin/python3.11 /usr/local/bin/python \
    && ln -sf /usr/bin/python3.11 /usr/local/bin/python3 \
    && ln -sf /usr/bin/pip3 /usr/local/bin/pip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/lc0 /usr/local/bin/lc0

RUN curl --connect-timeout 10 --max-time 60 -fsSL \
        "https://storage.lczero.org/files/networks-contrib/t1-512x15x8h-distilled-swa-3395000.pb.gz" \
        -o /usr/local/share/lc0-network.pb.gz || true

COPY pyproject.toml README.md ./
COPY lc0_worker ./lc0_worker
COPY handler.py ./

RUN pip install --no-cache-dir .

CMD ["python", "handler.py"]
