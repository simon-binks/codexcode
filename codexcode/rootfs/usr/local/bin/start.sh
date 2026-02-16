#!/usr/bin/env bash
set -euo pipefail

export HA_TOKEN="${SUPERVISOR_TOKEN:-}"
export HA_URL="http://supervisor/core"

PERSIST_DIR="/homeassistant/.codexcode"
CONFIG_TOML="${PERSIST_DIR}/config.toml"
mkdir -p "${PERSIST_DIR}" /root/.config

# ---------------------------------------------------------------------------
# Generate guidance docs
# ---------------------------------------------------------------------------
cat > "${PERSIST_DIR}/CODEX.md" <<'DOCEOF'
# Codex Code - Home Assistant Add-on

## Path Mapping

In this add-on container, paths are mapped differently than HA Core:
- `/homeassistant` = HA config directory (equivalent to `/config` in HA Core)
- `/config` may not exist; use `/homeassistant`

When users mention `/config/...`, translate to `/homeassistant/...`.

## Available Paths

| Path | Description | Access |
|------|-------------|--------|
| `/homeassistant` | HA configuration | read-write |
| `/share` | Shared folder | read-write |
| `/media` | Media files | read-write |
| `/ssl` | SSL certificates | read-only |
| `/backup` | Backups | read-only |

## Home Assistant Integration

Use `hass-mcp` and your client MCP configuration for Home Assistant integration.
For better performance, prefer domain-focused queries over full entity dumps.

## Authentication

If browser login callback fails with `localhost` errors inside ingress/container networking, use:
`codex-login`

This runs `codex login --device-auth`, which avoids local callback ports.

## Action Reliability

When executing state-changing actions (turn on/off, set temperature, etc):
1. Call the action tool once.
2. Immediately read back the target entity state.
3. Treat the operation as successful if the readback matches the requested state.

Some MCP action calls may return strict schema/validation errors in Codex even when Home Assistant has already applied the change.

## Reading Home Assistant Logs

```bash
# View recent logs (ha CLI)
ha core logs 2>&1 | tail -100

# Filter by keyword
ha core logs 2>&1 | grep -i keyword

# Filter errors only
ha core logs 2>&1 | grep -iE "(error|exception)"

# Alternative: read log file directly
tail -100 /homeassistant/home-assistant.log
```
DOCEOF

cat > "${PERSIST_DIR}/HA_TUNING.md" <<'DOCEOF'
# Home Assistant Tuning for Codex

Use these rules to improve speed and reliability:

1. Avoid full entity dumps (`hass://entities`) unless explicitly requested.
2. Prefer targeted queries:
   - domain summary and search first
   - specific entity readbacks for verification
3. For state-changing actions:
   - perform one action call
   - immediately read back entity state
   - report observed state as source of truth
4. If a tool returns validation/type errors after an action, still verify entity state before reporting failure.
5. Use domain-scoped requests (`light`, `switch`, `climate`) to keep responses small and fast.
DOCEOF

cat > "${PERSIST_DIR}/SESSION_PROMPT.txt" <<'DOCEOF'
Read `/homeassistant/.codexcode/CODEX.md` and `/homeassistant/.codexcode/HA_TUNING.md` first.
Then use Home Assistant MCP with these priorities:
- Avoid full entity dumps unless explicitly asked.
- Prefer targeted domain/entity queries.
- For actions, always verify final entity state and report success/failure from readback state.
DOCEOF

# ---------------------------------------------------------------------------
# Symlink Codex CLI state to persistent storage
#   ~/.codex  →  config.toml, auth.json, log/, skills/
# ---------------------------------------------------------------------------
if [ ! -L /root/.codex ]; then
  rm -rf /root/.codex
  ln -s "${PERSIST_DIR}" /root/.codex
fi

# ---------------------------------------------------------------------------
# Read add-on options (single jq call instead of six)
# ---------------------------------------------------------------------------
OPTIONS_FILE="/data/options.json"
eval "$(jq -r '
  "FONT_SIZE="   + (.terminal_font_size // 14 | tostring),
  "THEME="       + (.terminal_theme // "dark"),
  "SESSION_PERSIST=" + (.session_persistence // true | tostring),
  "ENABLE_MCP="  + (.enable_mcp // true | tostring),
  "ENABLE_PLAYWRIGHT=" + (.enable_playwright_mcp // false | tostring),
  "PLAYWRIGHT_HOST="  + (.playwright_cdp_host // ""),
  "AUTO_UPDATE_CODEX=" + (.auto_update_codex // false | tostring)
' "${OPTIONS_FILE}")"

# ---------------------------------------------------------------------------
# Auto-detect Playwright Browser hostname (if needed)
# ---------------------------------------------------------------------------
if [ -z "${PLAYWRIGHT_HOST}" ] && [ "${ENABLE_PLAYWRIGHT}" = "true" ]; then
  echo "[INFO] Auto-detecting Playwright Browser hostname..."
  PLAYWRIGHT_HOST="$(
    curl -s -H "Authorization: Bearer ${SUPERVISOR_TOKEN:-}" http://supervisor/addons \
      | jq -r '.data.addons[] | select(.slug | endswith("playwright-browser") or endswith("_playwright-browser")) | .hostname' \
      | head -1
  )"
  if [ -n "${PLAYWRIGHT_HOST}" ] && [ "${PLAYWRIGHT_HOST}" != "null" ]; then
    echo "[INFO] Found Playwright Browser: ${PLAYWRIGHT_HOST}"
  else
    echo "[WARN] Playwright Browser add-on not found, using default hostname"
    PLAYWRIGHT_HOST="playwright-browser"
  fi
fi

# ---------------------------------------------------------------------------
# Auto-update Codex CLI (if enabled)
# ---------------------------------------------------------------------------
if [ "${AUTO_UPDATE_CODEX}" = "true" ]; then
  echo "[INFO] Checking for Codex updates..."
  npm update -g @openai/codex 2>/dev/null || echo "[WARN] Codex update check failed, continuing..."
fi

# ---------------------------------------------------------------------------
# Write MCP config directly to config.toml
#
# This replaces the old approach of shelling out to `codex mcp add/remove`
# which spawned multiple Node.js processes and was slow + fragile.
#
# The hass-mcp launcher reads SUPERVISOR_TOKEN at runtime so the token
# is always fresh (fixes stale-token 500 errors after addon restarts).
# ---------------------------------------------------------------------------
MCP_HA_CWD="${PERSIST_DIR}/mcp/homeassistant"
mkdir -p "${MCP_HA_CWD}"

# Launcher script — reads SUPERVISOR_TOKEN at runtime, never bakes it in
cat > "${MCP_HA_CWD}/hass-mcp-launcher.sh" <<'LAUNCHEREOF'
#!/usr/bin/env bash
export HA_URL="http://supervisor/core"
export HA_TOKEN="${SUPERVISOR_TOKEN}"
exec hass-mcp
LAUNCHEREOF
chmod 700 "${MCP_HA_CWD}/hass-mcp-launcher.sh"

# Build config.toml — preserve auth.json and any user customisations
# by merging MCP sections on top of existing config
{
  # Preserve any existing non-MCP config lines (model, approval_policy, etc.)
  if [ -f "${CONFIG_TOML}" ]; then
    # Strip old mcp_servers sections — we regenerate them below
    sed '/^\[mcp_servers\./,/^$/d; /^\[mcp_servers\]/d' "${CONFIG_TOML}" \
      | sed '/^$/N;/^\n$/d'  # collapse double blank lines
  fi

  echo ""

  if [ "${ENABLE_MCP}" = "true" ]; then
    cat <<MCPEOF

[mcp_servers.homeassistant]
command = "${MCP_HA_CWD}/hass-mcp-launcher.sh"
args = []
startup_timeout_sec = 15.0
tool_timeout_sec = 30.0

[mcp_servers.homeassistant.env]
SUPERVISOR_TOKEN = "${SUPERVISOR_TOKEN:-}"
MCPEOF
  fi

  if [ "${ENABLE_PLAYWRIGHT}" = "true" ]; then
    cat <<MCPEOF

[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp", "--cdp-endpoint", "http://${PLAYWRIGHT_HOST}:9222"]
startup_timeout_sec = 15.0
tool_timeout_sec = 30.0
MCPEOF
  fi
} > "${CONFIG_TOML}.tmp"

mv "${CONFIG_TOML}.tmp" "${CONFIG_TOML}"

# Log what was configured (to stdout, not into the config file)
if [ "${ENABLE_MCP}" = "true" ]; then
  echo "[INFO] MCP 'homeassistant' configured (token passed at runtime via launcher)"
else
  echo "[INFO] MCP disabled"
fi
if [ "${ENABLE_PLAYWRIGHT}" = "true" ]; then
  echo "[INFO] MCP 'playwright' configured (CDP: http://${PLAYWRIGHT_HOST}:9222)"
else
  echo "[INFO] Playwright MCP disabled"
fi

# ---------------------------------------------------------------------------
# Terminal theme
# ---------------------------------------------------------------------------
if [ "${THEME}" = "dark" ]; then
  COLORS="background=#1e1e2e,foreground=#cdd6f4,cursor=#f5e0dc"
else
  COLORS="background=#eff1f5,foreground=#4c4f69,cursor=#dc8a78"
fi

if [ "${SESSION_PERSIST}" = "true" ]; then
  SHELL_CMD=(tmux new-session -A -s codex)
else
  SHELL_CMD=(bash --login)
fi

cd /homeassistant
exec ttyd --port 7681 --writable --ping-interval 30 --max-clients 5 \
  -t "fontSize=${FONT_SIZE}" \
  -t "fontFamily=Monaco,Consolas,monospace" \
  -t "scrollback=20000" \
  -t "theme=${COLORS}" \
  "${SHELL_CMD[@]}"
