OP RV2 — Ubuntu fixes & repro

Кратко
- Репозитория и скрипты для фиксов, применённых к Orange Pi RV2 (Ubuntu 24.04, riscv64).
- Здесь — шаги, команды и скрипт для воспроизведения: исправления APT/репо, перенос ключей, переход на Podman, установка podman-compose.

Что сделано
- Устранён warning APT: ограничил архитектуры в `docker`-репо и указал `signed-by`.
- Импортирован GPG-ключ в `/usr/share/keyrings/docker-archive-keyring.gpg` (apt-key deprecation).
- Временно проверяли `docker.io` (ubuntu-ports/riscv64) — затем перешли на `podman` + `podman-docker`.
- Установлен `podman-compose` из репозитория (тест пройден).
- Удалён лишний бэкап `docker.list.pre-fix`; оставлен бэкап `docker.list.bak`.
- Добавлен пользователь `orangepi` в группу `docker` (для совместимости `docker` CLI -> `podman`).

Файлы
- `00_setup_fixes.sh` — idempotent скрипт, воспроизводит ключевые правки и установки.
- `CHANGELOG.md` — краткая история действий.

Как использовать
1) Просмотреть: `cat README.md`
2) Запустить (на Orange Pi, от root):
   chmod +x 00_setup_fixes.sh
   sudo ./00_setup_fixes.sh
3) Проверки (на устройстве):
   uname -m
   dpkg --print-architecture
   apt update
   podman --version
   podman-compose --version
   podman run --rm docker.io/library/busybox uname -m

Примечания
- `docker-compose` (плагин) недоступен для riscv64 — используем `podman-compose`.
- Docker CE (официальный docker-ce) не предоставляет riscv64-пакетов; `docker.io` из ubuntu-ports доступен, но podman лучше для этой платформы.

Дальше
- При желании добавлю systemd-юнит для конкретного `podman-compose` проекта или перенесу ваши docker-compose файлы.
