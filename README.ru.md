# ORANGE PI RV2 Ollama — Руководство (кратко)

Этот репозиторий содержит скрипты и инструкции для подготовки Orange Pi RV2 и установки Ollama.

## Быстрый старт (чистая система)

1) Примените исправления ОС (рекомендуется):

```bash
cd OP_RV2_UBUNTU_Fix
sudo ./00_setup_fixes.sh
```

2) Установите Ollama (SpacemiT):

```bash
cd "ORANGE PI RV2  AI READY"
chmod +x ./install_ollama_rv2_spacemit.sh
sudo ./install_ollama_rv2_spacemit.sh
```

3) Тестирование:

```bash
sudo ./test_ollama_rv2.sh
```

## Где читать дальше
- Инструкция по установке: `ORANGE PI RV2  AI READY/README.md`
- Руководство пользователя: `ORANGE PI RV2  AI READY/USER_GUIDE.md`

Если нужно — откройте issue с пометкой `enhancement` для перевода других разделов.
