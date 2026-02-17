# ORANGE PI RV2 AI READY

This is a consolidated, end-to-end log of the working installation path from a clean Ubuntu 24.04 system on Orange Pi RV2 (SpacemiT K1) to a running Ollama server accessible from other machines.

All steps below are based on the actual working session and verified on 2026-02-17.

---

## 0) Target hardware and OS

- Board: Orange Pi RV2 (SpacemiT K1, RISC-V)
- OS: Ubuntu 24.04 (Orange Pi image)
- Storage: NVMe mounted and used for models and temp

Notes:
- Ollama official installer does not support riscv64.
- Building from source failed due to RVV intrinsics (ggml/llama.cpp).
- The working solution used SpacemiT prebuilt Ollama binaries.

---

## 1) System update

Run as root or via sudo:

```
apt update
apt upgrade -y
apt full-upgrade -y
reboot
```

---

## 2) Base dependencies

```
apt install -y cmake gcc git gcc-14
```

---

## 3) NVMe mount and swap (required)

This system already had NVMe mounted at root and a swap file at /mnt/nvme.
If you are on a clean system, ensure the following exist:

- /mnt/nvme
- /mnt/nvme/ollama/models
- /mnt/nvme/tmp
- 8G swap file at /mnt/nvme/swapfile

If your NVMe is mounted elsewhere, set `NVME_MOUNT` when running the installer:

```
NVME_MOUNT=/your/mount/path sudo ./install_ollama_rv2_spacemit.sh
```

Typical commands:

```
mkdir -p /mnt/nvme/tmp /mnt/nvme/ollama/models
fallocate -l 8G /mnt/nvme/swapfile
chmod 600 /mnt/nvme/swapfile
mkswap /mnt/nvme/swapfile
swapon /mnt/nvme/swapfile
```

---

## 4) Performance tweaks (recommended)

CPU governor:

```
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Persist via cron:

```
(crontab -l 2>/dev/null; echo "@reboot echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor") | crontab -
```

NVMe IO scheduler:

```
echo none | tee /sys/block/nvme0n1/queue/scheduler
```

Persist via udev:

```
echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-ioschedulers.rules
udevadm control --reload-rules
```

---

## 5) Go (for completeness)

Go 1.23.2 was installed earlier. It is not required for the prebuilt binary, but keep it documented:

```
wget https://go.dev/dl/go1.23.2.linux-riscv64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.2.linux-riscv64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

To avoid toolchain auto-download on slow networks:

```
export GOTOOLCHAIN=local
/usr/local/go/bin/go env -w GOTOOLCHAIN=local
```

---

## 6) Working solution: SpacemiT prebuilt Ollama

The plain URL failed due to the + character. Use URL-encoded %2B.

```
cd ~
wget -O spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz \
  "https://archive.spacemit.com/spacemit-ai/ollama/spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz"

tar -xzf spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz
ls -la spacemit-ollama.riscv64.0.6.8+spacemit
```

Install:

```
mv spacemit-ollama.riscv64.0.6.8+spacemit/ollama /usr/local/bin/ollama
chmod +x /usr/local/bin/ollama
/usr/local/bin/ollama --version
```

Expected version:

```
0.6.8+spacemit
```

---

## 6.1) Repeatable install script (recommended)

Use the full installer script from this folder on a clean system:

```
chmod +x ./install_ollama_rv2_spacemit.sh
sudo ./install_ollama_rv2_spacemit.sh
```

Optional:

- Skip the test model download: `RUN_TEST=0`.
- Change test model/prompt: `TEST_MODEL=... TEST_PROMPT=...`.

---

## 7) Systemd service with external access

Create /etc/systemd/system/ollama.service:

```
[Unit]
Description=Ollama
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/mnt/nvme/ollama/models"
Environment="OLLAMA_TMPDIR=/mnt/nvme/tmp"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
```

Enable and start:

```
systemctl daemon-reload
systemctl enable --now ollama
systemctl status ollama --no-pager
```

Verify listening:

```
ss -ltnp | grep 11434
```

Expected:

```
LISTEN ... *:11434 ... ollama
```

---

## 8) Test model (verified)

```
ollama run qwen2.5:0.5b "Hello from Orange Pi RV2"
```

The model downloaded to /mnt/nvme/ollama/models and replied successfully.

---

## 8.1) Standalone test script

Use this to re-test later without reinstalling:

```
chmod +x ./test_ollama_rv2.sh
sudo ./test_ollama_rv2.sh
```

Optional:

- `MODEL=...`
- `PROMPT=...`
- `HOST_URL=http://127.0.0.1:11434`

---

## 9) Home Assistant connection

Use the network address:

```
http://192.168.1.78:11434
```

If HA reports errors, check connectivity from another machine:

```
curl http://192.168.1.78:11434/api/tags
```

---

## 10) Troubleshooting notes

- Source build failed due to RVV intrinsics in ggml (vint8m2_t errors).
- SpacemiT package repo was unreachable (TLS/NODATA, HTTP refused); use the archive link above instead.
- If you see localhost-only binding, ensure OLLAMA_HOST is set to 0.0.0.0 in systemd.

---

## 11) Optional OpenWebUI (not installed in this run)

If desired, request the prebuilt SpacemiT OpenWebUI and run it separately.

---

End of verified installation log.
