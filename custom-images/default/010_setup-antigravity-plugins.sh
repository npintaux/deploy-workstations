#!/bin/bash
set -euo pipefail

LOG_FILE="/var/log/workstation_startup.log"
log() {
  local msg="$1"
  if [ -w "$LOG_FILE" ] || [ -w "$(dirname "$LOG_FILE" 2>/dev/null)" ]; then
    echo "$msg" | tee -a "$LOG_FILE"
  else
    echo "$msg"
  fi
}

USER_NAME="${USER:-user}"
if [ "$USER_NAME" = "root" ]; then
  USER_NAME="user"
fi
USER_HOME="${HOME:-/home/${USER_NAME}}"
if [ "$USER_HOME" = "/root" ]; then
  USER_HOME="/home/${USER_NAME}"
fi

AGY_CONFIG_DIR="${USER_HOME}/.gemini/config"
AGY_PLUGINS_DIR="${AGY_CONFIG_DIR}/plugins"
AGY_CLI_DIR="${USER_HOME}/.gemini/antigravity-cli"
AGY_SCRIPTS_DIR="${AGY_CLI_DIR}/scripts"
AGY_SETTINGS_FILE="${AGY_CLI_DIR}/settings.json"

log "=== Initializing Antigravity Plugins & Settings Setup ==="
log "Target plugins directory: ${AGY_PLUGINS_DIR}"

mkdir -p "${AGY_PLUGINS_DIR}" "${AGY_SCRIPTS_DIR}" "${AGY_CLI_DIR}/scratch"

# # 1. Install / Clone meta-skills plugin from GitHub
# if [ ! -d "${AGY_PLUGINS_DIR}/meta-skills" ]; then
#   log "Cloning meta-skills plugin from GitHub..."
#   git clone --depth 1 https://github.com/npintaux/meta-skills.git "${AGY_PLUGINS_DIR}/meta-skills" || log "Warning: Failed to clone meta-skills plugin"
# else
#   log "meta-skills plugin is already installed at ${AGY_PLUGINS_DIR}/meta-skills."
# fi

# # 2. Install / Clone sdd-plugin from GitHub
# if [ ! -d "${AGY_PLUGINS_DIR}/sdd-plugin" ]; then
#   log "Cloning sdd-plugin from GitHub..."
#   git clone --depth 1 https://github.com/npintaux/sdd-plugin.git "${AGY_PLUGINS_DIR}/sdd-plugin" || log "Warning: Failed to clone sdd-plugin"
# else
#   log "sdd-plugin is already installed at ${AGY_PLUGINS_DIR}/sdd-plugin."
# fi

# 3. Install custom statusline script (shows context filling & token counts)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "/usr/local/statusline.sh" ]; then
  log "Installing Antigravity statusline script to ${AGY_SCRIPTS_DIR}/statusline.sh..."
  cp /usr/local/statusline.sh "${AGY_SCRIPTS_DIR}/statusline.sh"
  chmod +x "${AGY_SCRIPTS_DIR}/statusline.sh"
elif [ -f "${SCRIPT_DIR}/statusline.sh" ]; then
  log "Installing Antigravity statusline script from ${SCRIPT_DIR} to ${AGY_SCRIPTS_DIR}/statusline.sh..."
  cp "${SCRIPT_DIR}/statusline.sh" "${AGY_SCRIPTS_DIR}/statusline.sh"
  chmod +x "${AGY_SCRIPTS_DIR}/statusline.sh"
fi

# 4. Configure Antigravity CLI settings (default model + Medium reasoning level & statusLine)
log "Configuring Antigravity CLI settings at ${AGY_SETTINGS_FILE}..."
AGY_DEFAULT_SETTINGS='{
  "model": "Gemini 3.8 Flash (Medium)",
  "statusLine": {
    "type": "command",
    "command": "~/.gemini/antigravity-cli/scripts/statusline.sh",
    "enabled": true
  }
}'

if [ -f "${AGY_SETTINGS_FILE}" ] && command -v jq >/dev/null 2>&1; then
  TMP_SETTINGS=$(mktemp)
  if jq -s '.[0] * .[1]' "${AGY_SETTINGS_FILE}" <(echo "${AGY_DEFAULT_SETTINGS}") > "${TMP_SETTINGS}" 2>/dev/null; then
    mv "${TMP_SETTINGS}" "${AGY_SETTINGS_FILE}"
  else
    rm -f "${TMP_SETTINGS}"
    echo "${AGY_DEFAULT_SETTINGS}" > "${AGY_SETTINGS_FILE}"
  fi
else
  echo "${AGY_DEFAULT_SETTINGS}" > "${AGY_SETTINGS_FILE}"
fi

# 5. Configure Antigravity environment variables (hide default logo)
log "Configuring Antigravity environment variables..."
ENV_FILE="/etc/profile.d/010_antigravity_env.sh"
if [ ! -f "$ENV_FILE" ]; then
  cat << 'EOF' > "$ENV_FILE"
export AGY_CLI_HIDE_LOGO="1"
EOF
  chmod +x "$ENV_FILE"
fi

if ! grep -q "AGY_CLI_HIDE_LOGO" "${USER_HOME}/.bashrc" 2>/dev/null; then
  echo 'export AGY_CLI_HIDE_LOGO="1"' >> "${USER_HOME}/.bashrc"
fi

# 6. Correct file permissions and ownership if running as root (e.g. via /etc/workstation-startup.d/)
if [ "$(id -u)" -eq 0 ]; then
  if id "${USER_NAME}" &>/dev/null; then
    log "Setting ownership of ${USER_HOME}/.gemini to ${USER_NAME}:${USER_NAME}..."
    chown -R "${USER_NAME}:${USER_NAME}" "${USER_HOME}/.gemini"
    if [ -f "${USER_HOME}/.bashrc" ]; then
      chown "${USER_NAME}:${USER_NAME}" "${USER_HOME}/.bashrc"
    fi
  fi
fi

log "=== Antigravity Plugins & Settings Setup Finished Successfully ==="
