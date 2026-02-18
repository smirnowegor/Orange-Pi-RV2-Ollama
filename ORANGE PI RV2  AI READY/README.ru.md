# ORANGE PI RV2 AI READY — Полная инструкция (перевод)

Ниже — перевод основного README по подготовке Orange Pi RV2 и установке Ollama (контент совпадает с оригиналом). Команды и пути оставлены без перевода.

---

## 0) Аппарат и ОС

- Плата: Orange Pi RV2 (SpacemiT K1, RISC-V)
- ОС: Ubuntu 24.04 (образ для Orange Pi)
- Хранилище: NVMe, используемый для моделей и временных файлов

Примечания:
- Официальный инсталлятор Ollama не поддерживает riscv64.
- Сборка из исходников не прошла из‑за RVV-интринсиксов (ggml/llama.cpp).
- Рабочее решение — prebuilt бинарники от SpacemiT.

---

## 1) Обновление системы

Выполните от root или через sudo:

```bash
apt update
apt upgrade -y
apt full-upgrade -y
reboot
```

---

## 2) Базовые зависимости

```bash
apt install -y cmake gcc git gcc-14
```

---

## 3) Монтирование NVMe и swap (обязательно)

Система должна иметь NVMe и swap-файл на NVMe. Проверяйте и создавайте:

- /mnt/nvme
- /mnt/nvme/ollama/models
- /mnt/nvme/tmp
- swap-файл ~8G в /mnt/nvme/swapfile

Типичные команды:

```bash
mkdir -p /mnt/nvme/tmp /mnt/nvme/ollama/models
fallocate -l 8G /mnt/nvme/swapfile
chmod 600 /mnt/nvme/swapfile
mkswap /mnt/nvme/swapfile
swapon /mnt/nvme/swapfile
```

Если NVMe смонтирован в другом месте, задайте NVME_MOUNT при запуске инсталлера:

```bash
NVME_MOUNT=/your/mount/path sudo ./install_ollama_rv2_spacemit.sh
```

---

## 4) Настройки производительности (рекомендуется)

CPU governor:

```bash
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

Persist (cron):

```bash
(crontab -l 2>/dev/null; echo "@reboot echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor") | crontab -
```

NVMe IO scheduler:

```bash
echo none | tee /sys/block/nvme0n1/queue/scheduler
```

Persist (udev):

```bash
echo 'ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"' > /etc/udev/rules.d/60-ioschedulers.rules
udevadm control --reload-rules
```

---

## 5) Go (для полноты)

Go 1.23.2 может быть установлена, но не обязательна для prebuilt-бинарника:

```bash
wget https://go.dev/dl/go1.23.2.linux-riscv64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.2.linux-riscv64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

---

## 6) Рабочее решение: SpacemiT prebuilt Ollama

Пример загрузки (URL содержит +, используйте URL-encoding):

```bash
cd ~
wget -O spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz \
  "https://archive.spacemit.com/spacemit-ai/ollama/spacemit-ollama.riscv64.0.6.8%2Bspacemit.tar.gz"

tar -xzf spacemit-ollama.riscv64.0.6.8+spacemit.tar.gz
ls -la spacemit-ollama.riscv64.0.6.8+spacemit
```

Установка:

```bash
mv spacemit-ollama.riscv64.0.6.8+spacemit/ollama /usr/local/bin/ollama
chmod +x /usr/local/bin/ollama
/usr/local/bin/ollama --version
```

Ожидаемая версия: `0.6.8+spacemit`

---

## 6.1) Повторяемый инсталлер (рекомендуется)

Запустите скрипт-установщик из этой папки на чистой системе:

```bash
chmod +x ./install_ollama_rv2_spacemit.sh
sudo ./install_ollama_rv2_spacemit.sh
```

Опции:
- `RUN_TEST=0` — пропустить скачивание тестовой модели
- `TEST_MODEL=... TEST_PROMPT=...` — изменить тест

---

## 7) systemd unit для внешнего доступа

Пример `/etc/systemd/system/ollama.service` приведён в оригинале — укажите `OLLAMA_HOST=0.0.0.0:11434` и `OLLAMA_MODELS=/mnt/nvme/ollama/models`.

Запуск:

```bash
systemctl daemon-reload
systemctl enable --now ollama
systemctl status ollama --no-pager
```

Проверьте прослушивание порта:

```bash
ss -ltnp | grep 11434
```

---

## 8) Тестирование модели

```bash
ollama run qwen2.5:0.5b "Hello from Orange Pi RV2"
```

Модель скачивается в `/mnt/nvme/ollama/models` и должна ответить.

---

## 8.1) Скрипт для быстрого теста

```bash
chmod +x ./test_ollama_rv2.sh
sudo ./test_ollama_rv2.sh
```

Опции: `MODEL=...`, `PROMPT=...`, `HOST_URL=...`

---

## 9) Подключение к Home Assistant

Используйте сетевой адрес:

```
http://192.168.1.78:11434
```

Проверьте доступность с другой машины:

```bash
curl http://192.168.1.78:11434/api/tags
```

---

## 10) Устранение неполадок

- Сборка из исходников может падать из‑за RVV-интринсиксов в ggml.
- Если пакет SpacemiT недоступен, используйте архивную ссылку выше.
- Если сервер слушает только localhost — проверьте `OLLAMA_HOST` в systemd.

---

## 11) OpenWebUI

По желанию можно запросить предсобранный SpacemiT OpenWebUI и запускать отдельно.

---

Конец перевода.