#!/usr/bin/env bash
set -euo pipefail

# Orange Pi RV2 (SpacemiT K1) - Ollama prebuilt installer
# Idempotent, intended for a clean Ubuntu 24.04 system.

ARCH=$(dpkg --print-architecture 2>/dev/null || true)
if [ "${ARCH}" != "riscv64" ]; then
  echo "ERROR: This script is intended for riscv64. Detected: ${ARCH:-unknown}" >&2
  exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

OLLAMA_VERSION="0.6.8+spacemit"
OLLAMA_TAR_URL="https://archive.spacemit.com/spacemit-ai/ollama/spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz"
OLLAMA_TAR_NAME="spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz"
OLLAMA_DIR="spacemit-ollama.riscv64.0.6.8+spacemit"
OLLAMA_BIN="/usr/local/bin/ollama"
NVME_MOUNT="${NVME_MOUNT:-/mnt/nvme}"
MODELS_DIR="${NVME_MOUNT}/ollama/models"
TMP_DIR="${NVME_MOUNT}/tmp"
SWAP_FILE="${NVME_MOUNT}/swapfile"
RUN_TEST="${RUN_TEST:-1}"
TEST_MODEL="${TEST_MODEL:-qwen2.5:0.5b}"
TEST_PROMPT="${TEST_PROMPT:-Hello from Orange Pi RV2}"

log() {
  echo "[rv2-ollama] $*"
}

log "Updating system packages"
apt update
apt upgrade -y
apt full-upgrade -y

log "Installing base dependencies"
apt install -y cmake gcc git gcc-14 curl

if ! mountpoint -q "${NVME_MOUNT}"; then
  echo "ERROR: ${NVME_MOUNT} is not mounted. Mount NVMe or set NVME_MOUNT to the correct path." >&2
  exit 1
fi

log "Ensuring NVMe directories"
mkdir -p "${MODELS_DIR}" "${TMP_DIR}"

if ! swapon --show | grep -q "${SWAP_FILE}"; then
  if [ ! -f "${SWAP_FILE}" ]; then
    log "Creating 8G swap at ${SWAP_FILE}"
    fallocate -l 8G "${SWAP_FILE}"
    chmod 600 "${SWAP_FILE}"
    mkswap "${SWAP_FILE}"
  fi
  log "Enabling swap"
  swapon "${SWAP_FILE}"
  if ! grep -q "${SWAP_FILE}" /etc/fstab; then
    echo "${SWAP_FILE} none swap sw 0 0" >> /etc/fstab
  fi
else
  log "Swap already enabled: ${SWAP_FILE}"
fi

log "Setting CPU governor to performance"
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
(crontab -l 2>/dev/null; echo "@reboot echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor") | crontab -

log "Setting NVMe IO scheduler to none"
if [ -e /sys/block/nvme0n1/queue/scheduler ]; then
  echo none | tee /sys/block/nvme0n1/queue/scheduler >/dev/null
  echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-ioschedulers.rules
  udevadm control --reload-rules
fi

log "Downloading Ollama ${OLLAMA_VERSION} (SpacemiT prebuilt)"
cd /root
curl -fL "${OLLAMA_TAR_URL}" -o "${OLLAMA_TAR_NAME}"

log "Extracting archive"
rm -rf "${OLLAMA_DIR}"
tar -xzf "${OLLAMA_TAR_NAME}"

if [ ! -f "${OLLAMA_DIR}/ollama" ]; then
  echo "ERROR: ollama binary not found in ${OLLAMA_DIR}" >&2
  exit 1
fi

log "Installing ollama binary"
install -m 0755 "${OLLAMA_DIR}/ollama" "${OLLAMA_BIN}"

log "Creating systemd service"
cat > /etc/systemd/system/ollama.service <<EOF
[Unit]
Description=Ollama
After=network.target

[Service]
Type=simple
User=root
ExecStart=${OLLAMA_BIN} serve
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=${MODELS_DIR}"
Environment="OLLAMA_TMPDIR=${TMP_DIR}"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ollama

log "Service status"
systemctl status ollama --no-pager

log "Ollama version"
${OLLAMA_BIN} --version || true

log "Listening sockets"
ss -ltnp | grep 11434 || true

if [ "${RUN_TEST}" = "1" ]; then
  log "Testing model: ${TEST_MODEL}"
  ${OLLAMA_BIN} run "${TEST_MODEL}" "${TEST_PROMPT}" || true
fi

cat <<'NOTES'

Next steps:
- Test: ollama run qwen2.5:0.5b "Hello from Orange Pi RV2"
- Home Assistant URL: http://<board-ip>:11434

NOTES
