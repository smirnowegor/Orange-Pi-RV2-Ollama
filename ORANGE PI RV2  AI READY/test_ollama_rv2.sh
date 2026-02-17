#!/usr/bin/env bash
set -euo pipefail

OLLAMA_BIN="/usr/local/bin/ollama"
MODEL="${MODEL:-qwen2.5:0.5b}"
PROMPT="${PROMPT:-Hello from Orange Pi RV2}"
HOST_URL="${HOST_URL:-http://127.0.0.1:11434}"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root or use sudo." >&2
  exit 1
fi

if [ ! -x "${OLLAMA_BIN}" ]; then
  echo "Ollama бинарник не найден: ${OLLAMA_BIN}" >&2
  exit 1
fi

systemctl is-active --quiet ollama || systemctl start ollama

echo "[test] Checking API: ${HOST_URL}/api/tags"
curl -fsS "${HOST_URL}/api/tags" | head -c 200 || true

echo

echo "[test] Running model: ${MODEL}"
"${OLLAMA_BIN}" run "${MODEL}" "${PROMPT}"
