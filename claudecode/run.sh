#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

# ==============================================================================
# Claude Code Home Assistant Add-on
# Starts ttyd with Claude Code configured for Home Assistant
# ==============================================================================

# Read configuration options
ANTHROPIC_API_KEY=$(bashio::config 'anthropic_api_key')
ENABLE_MCP=$(bashio::config 'enable_mcp')
WORKING_DIR=$(bashio::config 'working_directory')

# Validate API key
if [[ -z "${ANTHROPIC_API_KEY}" ]]; then
    bashio::log.error "Anthropic API key is not configured!"
    bashio::log.error "Please set your API key in the add-on configuration."
    bashio::exit.nok
fi

# Export environment variables
export ANTHROPIC_API_KEY
export HOME=/root
export TERM=xterm-256color

# Configure MCP if enabled
if bashio::var.true "${ENABLE_MCP}"; then
    bashio::log.info "Configuring Home Assistant MCP server..."

    # Get Supervisor token for Home Assistant API access
    SUPERVISOR_TOKEN="${SUPERVISOR_TOKEN:-}"

    # Create Claude MCP configuration
    mkdir -p /root/.claude
    cat > /root/.claude/settings.json << EOF
{
  "mcpServers": {
    "homeassistant": {
      "command": "hass-mcp",
      "env": {
        "HASS_TOKEN": "${SUPERVISOR_TOKEN}",
        "HASS_HOST": "http://supervisor/core"
      }
    }
  }
}
EOF

    bashio::log.info "MCP server configured for Home Assistant integration"
fi

# Create a shell profile for Claude Code
cat > /root/.profile << 'EOF'
export TERM=xterm-256color
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"

# Welcome message
echo ""
echo "========================================"
echo "  Claude Code for Home Assistant"
echo "========================================"
echo ""
echo "You can now use Claude Code to manage your Home Assistant."
echo ""
echo "Examples:"
echo "  claude \"List all my automations\""
echo "  claude \"Create an automation to turn on lights at sunset\""
echo "  claude \"Debug my configuration.yaml\""
echo ""
echo "Type 'claude' to start an interactive session."
echo ""
EOF

# Start ttyd with bash
bashio::log.info "Starting Claude Code web terminal..."
bashio::log.info "Working directory: ${WORKING_DIR}"

cd "${WORKING_DIR}" || cd /homeassistant

# Start ttyd with ingress support
exec ttyd \
    --port 7681 \
    --writable \
    --base-path "$(bashio::addon.ingress_entry)" \
    bash --login
