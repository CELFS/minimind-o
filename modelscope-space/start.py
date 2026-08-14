# ModelScope 创空间启动脚本：使用密文变量下载 CELFSS/MiniMind-3o 私有模型后启动 WebUI。
# 使用方式：在创空间密文管理中配置 MODELSCOPE_API_TOKEN，然后执行 python start.py。

import os
import sys

from modelscope import snapshot_download


ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(ROOT_DIR, 'runtime-models')
MODEL_DIR = os.path.join(MODELS_DIR, 'minimind-3o')
MODEL_FILES = {
    'pytorch_model.bin',
    'model.safetensors',
    'pytorch_model.bin.index.json',
    'model.safetensors.index.json',
}


def ensure_private_model():
    os.makedirs(MODEL_DIR, exist_ok=True)
    if MODEL_FILES.intersection(os.listdir(MODEL_DIR)):
        return
    token = os.environ.get('MODELSCOPE_API_TOKEN', '').strip()
    if not token:
        raise RuntimeError('缺少 MODELSCOPE_API_TOKEN，请先在创空间密文管理中配置魔塔访问令牌')
    snapshot_download('CELFSS/MiniMind-3o', local_dir=MODEL_DIR, token=token)


if __name__ == '__main__':
    ensure_private_model()
    os.execv(sys.executable, [
        sys.executable,
        os.path.join(ROOT_DIR, 'webui', 'web_demo.py'),
        '--load_from', MODELS_DIR,
        '--device', 'cpu',
        '--port', '7860',
    ])
