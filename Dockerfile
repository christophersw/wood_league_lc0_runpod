# RTX 5090 (Blackwell / sm_120) requires CUDA >= 12.8
FROM nvidia/cuda:12.8.1-cudnn-devel-ubuntu22.04

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    LC0_NETWORK=/usr/local/share/lc0-network.pb.gz \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.11 \
        python3.11-venv \
        python3-pip \
        curl \
        git \
        meson \
        ninja-build \
        build-essential \
        libopenblas-dev \
        zlib1g-dev \
    && ln -sf /usr/bin/python3.11 /usr/local/bin/python \
    && ln -sf /usr/bin/python3.11 /usr/local/bin/python3 \
    && ln -sf /usr/bin/pip3 /usr/local/bin/pip \
    && rm -rf /var/lib/apt/lists/*

# Build lc0 with CUDA backend targeting Blackwell (sm_120)
# NVCC_FLAGS sets the GPU arch; lc0 uses meson which doesn't have a cuda_arch option
RUN git clone --recurse-submodules https://github.com/LeelaChessZero/lc0.git /tmp/lc0 \
    && cd /tmp/lc0 \
    && NVCC_FLAGS="-arch=sm_120" ./build.sh -Dbackends=cuda \
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
