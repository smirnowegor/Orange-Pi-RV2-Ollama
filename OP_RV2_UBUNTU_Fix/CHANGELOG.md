CHANGELOG — OP_RV2_UBUNTU_Fix

2026-02-17 — initial
- Investigated apt warnings and fixed `docker.list` to limit architectures.
- Imported Docker GPG key into `/usr/share/keyrings` and removed legacy apt-key usage.
- Installed `docker.io` for testing, then migrated to `podman` + `podman-docker` for production on riscv64.
- Installed `podman-compose` and verified container launch (busybox, hello-world).
- Created `00_setup_fixes.sh` to reproduce the main fixes.
