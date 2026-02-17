# ORANGE PI RV2 Ollama User Guide

This file is for day-to-day use: how to verify Ollama is working, how to test a model from the terminal, and which models fit best on Orange Pi RV2.

---

## 1) Check that the server is running

Local (on the board):

```
systemctl status ollama --no-pager
ss -ltnp | grep 11434
curl http://127.0.0.1:11434/api/tags
```

From another PC on the same network:

```
curl http://192.168.1.78:11434/api/tags
```

If the external call fails, check:
- OLLAMA_HOST is set to 0.0.0.0:11434 in the systemd unit
- No firewall blocking port 11434

---

## 2) Run a model from the terminal

Interactive:

```
ollama run qwen2.5:0.5b
```

One-shot prompt:

```
ollama run qwen2.5:0.5b "Hello from Orange Pi RV2"
```

List installed models:

```
ollama list
```

Remove a model:

```
ollama rm qwen2.5:0.5b
```

---

## 3) Recommended models for RV2 (CPU-only)

Goal: stable performance and memory fit on 4-8GB RAM. Use small models first.

### Best balance (recommended)
- qwen2.5:0.5b (fastest, very light)
- qwen2.5:1.5b (better quality, still usable)
- llama3.2:1b (good general model, light)
- tinyllama:1.1b (very light, older)

### Acceptable (slower, may be tight on 4GB)
- qwen2.5:3b (needs more RAM, slower)
- phi3:3.8b (bigger, slower)

### Not recommended on RV2
- 7b and above (too slow or memory-heavy on CPU-only)

---

## 4) Performance comparison (typical CPU-only)

Approximate for RV2 (SpacemiT K1, CPU-only, RVV patched build):

- qwen2.5:0.5b   -> ~3-5 tok/s
- qwen2.5:1.5b   -> ~1-2 tok/s
- llama3.2:1b    -> ~1-2 tok/s
- tinyllama:1.1b -> ~1-2 tok/s
- qwen2.5:3b     -> <1 tok/s (often too slow)

These are rough, real speed depends on temperature, swap activity, and model quantization.

---

## 5) Tips to keep it stable

- Keep models on NVMe: OLLAMA_MODELS=/mnt/nvme/ollama/models
- Use swap on NVMe (8GB) to prevent OOM
- Ensure CPU governor is set to performance
- Keep good cooling (compile and inference can reach 80C+)

---

## 6) Quick troubleshooting

- "Connection refused" from another PC:
  - Check port: ss -ltnp | grep 11434
  - Ensure OLLAMA_HOST=0.0.0.0:11434 in systemd

- "Killed" or OOM:
  - Use smaller model
  - Ensure swap is enabled

- Very slow:
  - Use 0.5b or 1b models
  - Check temperature and swap usage

---

End of user guide.
