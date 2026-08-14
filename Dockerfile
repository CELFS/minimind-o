FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    REQUIRE_ORIGIN_AUTH=1

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates ffmpeg git git-lfs libsndfile1 \
    && git lfs install --system \
    && rm -rf /var/lib/apt/lists/*

RUN GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://modelscope.cn/studios/gongjy/MiniMind-O.git /modelscope-upstream \
    && cd /modelscope-upstream \
    && git lfs pull --include="minimind-3o/**,model/SenseVoiceSmall/**,model/mimi/**" --exclude="" \
    && mkdir -p /app/runtime-models /app/model \
    && cp -R /modelscope-upstream/minimind-3o /app/runtime-models/minimind-3o \
    && cp -R /modelscope-upstream/model/SenseVoiceSmall /app/model/SenseVoiceSmall \
    && cp -R /modelscope-upstream/model/mimi /app/model/mimi \
    && rm -rf /modelscope-upstream

COPY requirements-deploy.txt ./requirements-deploy.txt

RUN python -m pip install --upgrade pip \
    && python -m pip install --index-url https://download.pytorch.org/whl/cpu torch==2.6.0 torchaudio==2.6.0 \
    && python -m pip install -r requirements-deploy.txt

COPY . .

EXPOSE 7860

CMD ["python", "webui/web_demo.py", "--load_from", "runtime-models", "--device", "cpu", "--port", "7860"]
