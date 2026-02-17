# ORANGE PI RV2 AI READY

Standalone repository for Orange Pi RV2 system fixes and AI/Ollama setup.

## Contents

- OP_RV2_UBUNTU_Fix
  - Base OS fixes, Podman setup, and utilities.
- ORANGE PI RV2  AI READY
  - Ollama installation, repeatable scripts, and user guides.

## Quick start (clean system)

1) Apply base fixes (optional but recommended):

```
cd OP_RV2_UBUNTU_Fix
sudo ./00_setup_fixes.sh
```

2) Install Ollama (SpacemiT prebuilt):

```
cd "..\ORANGE PI RV2  AI READY"
chmod +x ./install_ollama_rv2_spacemit.sh
sudo ./install_ollama_rv2_spacemit.sh
```

3) Test the model:

```
sudo ./test_ollama_rv2.sh
```

## Docs

- System fixes: OP_RV2_UBUNTU_Fix/README.md
- Ollama setup: ORANGE PI RV2  AI READY/README.md
- User guide: ORANGE PI RV2  AI READY/USER_GUIDE.md
