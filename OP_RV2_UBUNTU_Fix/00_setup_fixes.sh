#!/usr/bin/env bash
set -euo pipefail

# OP RV2 UBUNTU Fix — idempotent helper to apply/check fixes and optionally
# install itself and enable passwordless sudo for the installed script.
# Usage:
#   (as root) ./00_setup_fixes.sh           -> apply fixes
#   ./00_setup_fixes.sh --install           -> copy to /usr/local/bin/op_rv2_fix
#   sudo /usr/local/bin/op_rv2_fix          -> run installed script (may be passwordless)
#   sudo ./00_setup_fixes.sh --enable-passwordless --user orangepi
#   ./00_setup_fixes.sh --uninstall         -> remove installed script + sudoers
#   ./00_setup_fixes.sh --check-sudo        -> used to test passwordless sudo for installed script

INSTALL_PATH=/usr/local/bin/op_rv2_fix
SUDOERS_FILE=/etc/sudoers.d/op_rv2_fix
SELF_PATH="$(readlink -f "$0")"

print_usage() {
  cat <<'USAGE'
OP RV2 UBUNTU Fix — helper
Options:
  --install                     Install script to /usr/local/bin (idempotent)
  --enable-passwordless [--user USER]
                                Install and add sudoers entry so USER can run
                                the installed script with NOPASSWD (safe, single-path)
  --create-service NAME --project-dir /path/to/project [--service-user USER]
                                Create and enable a systemd service that runs
                                `podman-compose` in the specified project directory
  --remove-service NAME         Stop/disable and remove the generated unit
  --uninstall                   Remove installed script and sudoers entry
  --check-sudo                  (no-op) exit 0 if sudo -n INSTALL_PATH works for the calling user
  -h, --help                    Show this help

Examples:
  sudo ./00_setup_fixes.sh --enable-passwordless --user orangepi
  /usr/local/bin/op_rv2_fix --install
  sudo /usr/local/bin/op_rv2_fix --create-service sample --project-dir /opt/sample --service-user orangepi
USAGE
}

require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "This action requires root. Re-run with sudo or as root." >&2
    exit 1
  fi
}

install_self() {
  require_root
  if [ "$(readlink -f "$SELF_PATH")" != "$INSTALL_PATH" ]; then
    echo "Installing script to $INSTALL_PATH"
    cp -a "$SELF_PATH" "$INSTALL_PATH"
    chmod 0755 "$INSTALL_PATH"
  else
    echo "Script already running from $INSTALL_PATH"
  fi
}

create_sudoers_for_user() {
  local user="$1"
  require_root
  echo "Creating sudoers entry for user: $user (NOPASSWD for $INSTALL_PATH)"
  cat > "$SUDOERS_FILE" <<EOF
# Allow $user to run the OP_RV2_UBUNTU_Fix script without a password
$user ALL=(ALL) NOPASSWD: $INSTALL_PATH
EOF
  chmod 0440 "$SUDOERS_FILE"
  if visudo -cf "$SUDOERS_FILE" >/dev/null 2>&1; then
    echo "Sudoers installed: $SUDOERS_FILE"
  else
    echo "ERROR: sudoers file invalid, removing" >&2
    rm -f "$SUDOERS_FILE"
    exit 1
  fi
}

remove_sudoers_and_install() {
  require_root
  if [ -f "$SUDOERS_FILE" ]; then
    rm -v "$SUDOERS_FILE" || true
  else
    echo "No $SUDOERS_FILE to remove"
  fi
  if [ -f "$INSTALL_PATH" ]; then
    rm -v "$INSTALL_PATH" || true
  else
    echo "No $INSTALL_PATH to remove"
  fi
}

# Create a simple systemd unit that runs podman-compose for a project directory
create_podman_compose_service() {
  local svc="$1" proj_dir="$2" svc_user="${3:-orangepi}"
  require_root
  if [ -z "$svc" ] || [ -z "$proj_dir" ]; then
    echo "create_podman_compose_service <name> <project_dir> [user]" >&2
    return 2
  fi
  if [ ! -d "$proj_dir" ]; then
    echo "Project directory does not exist: $proj_dir" >&2
    return 1
  fi
  local unit_file="/etc/systemd/system/${svc}.service"
  echo "Creating systemd unit $unit_file -> project: $proj_dir (user: $svc_user)"
  cat > "$unit_file" <<EOF
[Unit]
Description=Podman-Compose service: $svc
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Restart=always
RestartSec=10
WorkingDirectory=$proj_dir
ExecStart=/usr/bin/podman-compose -f docker-compose.yml up
ExecStop=/usr/bin/podman-compose -f docker-compose.yml down
User=$svc_user
Environment=PATH=/usr/local/bin:/usr/bin:/bin
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "$unit_file"
  systemctl daemon-reload
  systemctl enable --now "$svc" || { echo "Failed to enable/start $svc" >&2; return 1; }
  echo "Service $svc enabled and started"
}

remove_podman_compose_service() {
  local svc="$1"
  require_root
  if [ -z "$svc" ]; then
    echo "remove_podman_compose_service <name>" >&2
    return 2
  fi
  systemctl stop "$svc" 2>/dev/null || true
  systemctl disable "$svc" 2>/dev/null || true
  rm -f "/etc/systemd/system/${svc}.service"
  systemctl daemon-reload
  echo "Service $svc removed"
}

check_passwordless_for_user() {
  local user="$1"
  # run non-interactive sudo as that user; will fail if password is required
  runuser -l "$user" -c "sudo -n $INSTALL_PATH --check-sudo" >/dev/null 2>&1 && return 0 || return 1
}

# If user asked for --check-sudo, just exit 0 (used for test)
if [ "${1-}" = "--check-sudo" ]; then
  echo "CHECK-SUDO: OK"
  exit 0
fi

# Parse simple flags
ENABLE_PASSWORDLESS=0
DO_INSTALL=0
DO_UNINSTALL=0
CREATE_SERVICE=0
REMOVE_SERVICE=0
SERVICE_NAME=""
PROJECT_DIR=""
SERVICE_USER=""
TARGET_USER=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install) DO_INSTALL=1; shift ;;
    --enable-passwordless) ENABLE_PASSWORDLESS=1; shift ;;
    --create-service) CREATE_SERVICE=1; SERVICE_NAME="$2"; shift 2 ;;
    --remove-service) REMOVE_SERVICE=1; SERVICE_NAME="$2"; shift 2 ;;
    --project-dir) PROJECT_DIR="$2"; shift 2 ;;
    --service-user) SERVICE_USER="$2"; shift 2 ;;
    --user) TARGET_USER="$2"; shift 2 ;;
    --uninstall) DO_UNINSTALL=1; shift ;;
    --check-sudo) echo "CHECK-SUDO: OK"; exit 0 ;;
    -h|--help) print_usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; print_usage; exit 2 ;;
  esac
done

# service creation/removal takes precedence
if [ "$CREATE_SERVICE" -eq 1 ]; then
  if [ -z "$SERVICE_NAME" ] || [ -z "$PROJECT_DIR" ]; then
    echo "--create-service requires --project-dir and a service name" >&2; exit 2
  fi
  create_podman_compose_service "$SERVICE_NAME" "$PROJECT_DIR" "${SERVICE_USER:-orangepi}"
  exit $?
fi

if [ "$REMOVE_SERVICE" -eq 1 ]; then
  if [ -z "$SERVICE_NAME" ]; then
    echo "--remove-service requires a service name" >&2; exit 2
  fi
  remove_podman_compose_service "$SERVICE_NAME"
  exit $?
fi

if [ "$DO_UNINSTALL" -eq 1 ]; then
  remove_sudoers_and_install
  exit 0
fi

if [ "$DO_INSTALL" -eq 1 ]; then
  install_self
  exit 0
fi

if [ "$ENABLE_PASSWORDLESS" -eq 1 ]; then
  require_root
  # decide target user
  if [ -z "$TARGET_USER" ]; then
    TARGET_USER="${SUDO_USER:-$(awk -F: '($3>=1000 && $1!="nobody"){print $1; exit}' /etc/passwd)}"
  fi
  if [ -z "$TARGET_USER" ]; then
    echo "No non-root user found — provide --user <name>" >&2; exit 1
  fi
  install_self
  create_sudoers_for_user "$TARGET_USER"
  echo "Done. $TARGET_USER can now run: sudo $INSTALL_PATH  (without password)"
  exit 0
fi

# --- Default behaviour: apply the fixes (same as previous script) ---
if [ "$(id -u)" -ne 0 ]; then
  echo "Run the script as root (sudo) or install it to /usr/local/bin and enable passwordless sudo for your user:" >&2
  echo "  sudo ./00_setup_fixes.sh --enable-passwordless --user <you>" >&2
  exit 1
fi

echo "== OP RV2 UBUNTU Fix — apply/check fixes =="
ARCH=$(dpkg --print-architecture 2>/dev/null || true)
echo "Detected architecture: ${ARCH:-unknown}"

# 1) Ensure keyrings dir and import Docker GPG (safe if already present)
mkdir -p /usr/share/keyrings
if [ ! -f /usr/share/keyrings/docker-archive-keyring.gpg ]; then
  echo "Importing Docker GPG key to /usr/share/keyrings/docker-archive-keyring.gpg"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg || echo "⚠️  failed to import docker GPG (network?)"
else
  echo "Docker keyring already exists — skipping"
fi

# 2) Tidy docker.list: limit archs (do not request riscv64 from docker-ce mirror)
DOCKERLIST=/etc/apt/sources.list.d/docker.list
if [ -f "$DOCKERLIST" ]; then
  if ! grep -q "signed-by=/usr/share/keyrings/docker-archive-keyring.gpg" "$DOCKERLIST"; then
    cp "$DOCKERLIST" "$DOCKERLIST.bak" || true
    sed -i -E "s@^deb .*repo.huaweicloud.com/docker-ce/linux/ubuntu.*@deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://repo.huaweicloud.com/docker-ce/linux/ubuntu noble stable@g" "$DOCKERLIST" || true
    echo "Updated $DOCKERLIST (backup: $DOCKERLIST.bak)"
  else
    echo "$DOCKERLIST already contains signed-by and arch restriction"
  fi
fi

# remove stray backup left during interactive session
if [ -f /etc/apt/sources.list.d/docker.list.pre-fix ]; then
  rm -v /etc/apt/sources.list.d/docker.list.pre-fix || true
fi

# 3) Install Podman + podman-docker (if not already) and ensure uidmap for rootless
if ! command -v podman >/dev/null 2>&1; then
  apt update
  apt install -y podman podman-docker uidmap || { echo "Failed to install podman or uidmap" >&2; exit 1; }
  echo "podman (and uidmap) installed"
else
  # ensure uidmap/newuidmap exists for rootless users
  if ! command -v newuidmap >/dev/null 2>&1; then
    echo "Installing uidmap to provide newuidmap/newgidmap"
    apt update && apt install -y uidmap || echo "failed to install uidmap"
  fi
  echo "podman already installed"
fi

# 4) Install podman-compose if available
if ! command -v podman-compose >/dev/null 2>&1; then
  if apt-cache policy podman-compose | grep -q Candidate; then
    apt update
    apt install -y podman-compose || echo "podman-compose apt install failed"
  else
    echo "podman-compose not available via apt; consider pip install"
  fi
else
  echo "podman-compose already installed"
fi

# 5) Add a non-root user (first with UID>=1000) to group docker for CLI compat
USER_CANDIDATE=$(awk -F: '($3>=1000 && $1!="nobody"){print $1; exit}' /etc/passwd || true)
if [ -n "$USER_CANDIDATE" ]; then
  usermod -aG docker "$USER_CANDIDATE" || true
  echo "Added $USER_CANDIDATE to group docker (re-login required)"
else
  echo "No non-root user found to add to group docker"
fi

# 6) Final: update APT and show status
apt update || true

echo
echo "-- Verification hints --"
echo "Architecture: $(dpkg --print-architecture 2>/dev/null || echo unknown)"
echo "Podman: $(podman --version 2>/dev/null || echo not-installed)"
echo "podman-compose: $(podman-compose --version 2>/dev/null || echo not-installed)"
echo "docker (CLI shim): $(docker --version 2>/dev/null || echo not-present)"
echo "Run: podman run --rm docker.io/library/busybox uname -m"

echo "== Done =="