#!/usr/bin/env bash
# MiniMind-O Local Tunnel Service Script.
# Usage:
#   cp .env.local.example .env.local
#   ./scripts/minimind-local.sh start
#   ./scripts/minimind-local.sh check
# 'start' will launch the local model in the foreground; 'check' will verify the local service and Cloudflare Tunnel.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/.env.local"
PYTHON_BIN="${PROJECT_ROOT}/.conda-env/bin/python"

show_usage() {
  echo "Usage: $0 start|check"
}

start_service() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "Missing ${ENV_FILE}. Please run: cp .env.local.example .env.local"
    exit 1
  fi

  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a

  if [[ -z "${ORIGIN_SERVICE_TOKEN:-}" ]]; then
    echo "Please fill in ORIGIN_SERVICE_TOKEN in ${ENV_FILE}."
    exit 1
  fi

  if [[ ! -x "${PYTHON_BIN}" ]]; then
    echo "Python environment not found: ${PYTHON_BIN}"
    exit 1
  fi

  if [[ ! -d "${PROJECT_ROOT}/runtime-models/minimind-3o" ]]; then
    echo "Model directory not found: ${PROJECT_ROOT}/runtime-models/minimind-3o"
    exit 1
  fi

  export REQUIRE_ORIGIN_AUTH=1
  export VAD_THRESHOLD=0.7
  export VAD_PRE_SPEECH_MS=512

  cd "${PROJECT_ROOT}"
  exec "${PYTHON_BIN}" webui/web_demo.py \
    --load_from ./runtime-models \
    --device cpu \
    --port 7860 \
    --audio_chunk_frames 4 \
    --audio_overlap 2 \
    --max_history_turns 0
}

check_url() {
  local label="$1"
  local url="$2"

  if curl --fail --silent --show-error --max-time 15 "${url}" >/dev/null; then
    echo "[OK] ${label}: ${url}"
    return 0
  fi

  echo "[FAIL] ${label}: ${url}"
  return 1
}

check_service() {
  local failed=0

  check_url "Local Service" "http://127.0.0.1:7860/health" || failed=1
  check_url "Cloudflare Tunnel" "https://ai.celfs.site/health" || failed=1

  return "${failed}"
}

case "${1:-}" in
  start)
    start_service
    ;;
  check)
    check_service
    ;;
  *)
    show_usage
    exit 1
    ;;
esac
