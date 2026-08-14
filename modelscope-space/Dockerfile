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

RUN mkdir -p /app/runtime-models /app/model \
    && GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://modelscope.cn/studios/gongjy/MiniMind-O.git /modelscope-upstream \
    && cd /modelscope-upstream \
    && git lfs pull --include="model/SenseVoiceSmall/**,model/mimi/**,model/siglip2-base-p32-256-ve/**,model/speaker/**" --exclude="" \
    && cp -R /modelscope-upstream/model/SenseVoiceSmall /app/model/SenseVoiceSmall \
    && cp -R /modelscope-upstream/model/mimi /app/model/mimi \
    && cp -R /modelscope-upstream/model/siglip2-base-p32-256-ve /app/model/siglip2-base-p32-256-ve \
    && cp -R /modelscope-upstream/model/speaker /app/model/speaker \
    && mkdir -p /app/model/vad \
    && python -c "import hashlib, pathlib, urllib.request; data = urllib.request.urlopen('https://raw.githubusercontent.com/jingyaogong/minimind-o/c009567d06142182163f67836bedcb283ac409bc/model/vad/silero_vad.onnx', timeout=60).read(); actual = hashlib.sha256(data).hexdigest(); expected = '591f853590d11ddde2f2a54f9e7ccecb2533a8af7716330e8adfa6f3849787a9'; assert actual == expected, f'VAD checksum mismatch: {actual}'; pathlib.Path('/app/model/vad/silero_vad.onnx').write_bytes(data)" \
    && GIT_LFS_SKIP_SMUDGE=1 git clone --depth 1 https://modelscope.cn/models/gongjy/campplus.git /app/model/campplus \
    && cd /app/model/campplus \
    && git lfs pull \
    && rm -rf /app/runtime-models/minimind-3o/.git /app/model/campplus/.git /modelscope-upstream

COPY requirements-deploy.txt ./requirements-deploy.txt

RUN python -m pip install --upgrade pip \
    && python -m pip install --index-url https://download.pytorch.org/whl/cpu torch==2.6.0 torchaudio==2.6.0 \
    && python -m pip install -r requirements-deploy.txt

COPY . .

EXPOSE 7860

CMD ["python", "start.py"]
