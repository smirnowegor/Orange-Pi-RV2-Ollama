# ORANGE PI RV2 AI READY — руководство на русском

Репозиторий содержит скрипты и проверенные инструкции для подготовки Orange Pi RV2 и установки Ollama (рабочий путь, проверен на практике).

## Содержание
- `OP_RV2_UBUNTU_Fix` — исправления ОС и утилиты (подготовка системы)
- `ORANGE PI RV2  AI READY` — скрипты установки Ollama, повторяемые шаги и пользовательские руководства

## Быстрый старт (чистая система)

1) Примените исправления ОС (рекомендуется):

```bash
cd OP_RV2_UBUNTU_Fix
sudo ./00_setup_fixes.sh
```

2) Установите Ollama (SpacemiT prebuilt):

```bash
cd "ORANGE PI RV2  AI READY"
chmod +x ./install_ollama_rv2_spacemit.sh
sudo ./install_ollama_rv2_spacemit.sh
```

3) Протестируйте:

```bash
sudo ./test_ollama_rv2.sh
```

## Где читать дальше
- Подробная инструкция по установке: `ORANGE PI RV2  AI READY/README.md` (перевод в `ORANGE PI RV2  AI READY/README.ru.md`)
- Руководство пользователя: `ORANGE PI RV2  AI READY/USER_GUIDE.md` (перевод в `ORANGE PI RV2  AI READY/USER_GUIDE.ru.md`)

Если нужно перевести дополнительные разделы — откройте issue с меткой `enhancement`.
