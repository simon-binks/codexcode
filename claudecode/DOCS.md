# Claude Code for Home Assistant

This add-on allows you to run Claude Code, Anthropic's AI coding assistant, directly inside Home Assistant. Use it to create automations, debug configurations, and manage your smart home with natural language.

## Prerequisites

- An Anthropic API key (get one at https://console.anthropic.com/)
- Home Assistant with Supervisor (Home Assistant OS or Supervised installation)

## Installation

1. Add this repository to your Home Assistant add-on store:
   - Go to **Settings** > **Add-ons** > **Add-on Store**
   - Click the three dots in the top right corner
   - Select **Repositories**
   - Add: `https://github.com/robsonfelix/claudecode-hass-integration`

2. Find "Claude Code" in the add-on store and click **Install**

3. Configure your Anthropic API key in the add-on configuration

4. Start the add-on

5. Click **Open Web UI** or find "Claude Code" in your sidebar

## Configuration

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `anthropic_api_key` | Your Anthropic API key (required) | `""` |
| `enable_mcp` | Enable Home Assistant MCP integration | `true` |
| `working_directory` | Default working directory | `/homeassistant` |

### API Key

You must provide a valid Anthropic API key. Get one from https://console.anthropic.com/

1. Create an account or sign in
2. Navigate to API Keys
3. Create a new API key
4. Copy and paste it into the add-on configuration

## Usage

### Interactive Mode

Open the web UI and type `claude` to start an interactive Claude Code session:

```bash
claude
```

### One-off Commands

Run specific prompts directly:

```bash
claude "List all my automations"
claude "Create an automation that turns on the porch light when motion is detected"
claude "Fix the syntax error in my configuration.yaml"
```

### Example Tasks

**Creating Automations:**
```bash
claude "Create an automation that:
- Triggers at sunset
- Turns on the living room lights
- Only on weekdays"
```

**Debugging:**
```bash
claude "Check my configuration.yaml for errors"
claude "Why isn't my automation working? Check automations.yaml"
```

**Understanding Your Setup:**
```bash
claude "Explain how my heating automation works"
claude "List all devices in the kitchen"
```

## MCP Integration

When `enable_mcp` is enabled, Claude Code can directly interact with Home Assistant:

- **List entities**: Query all your devices, sensors, and entities
- **Call services**: Turn on lights, trigger scenes, etc.
- **View history**: Check entity state history
- **Get states**: See current state of any entity

This allows Claude to not just edit files, but actually understand and interact with your live Home Assistant instance.

## File Access

The add-on has read-write access to:

- `/homeassistant` - Your main configuration directory
- `/share` - Shared storage between add-ons
- `/ssl` - SSL certificates (read-only)

## Troubleshooting

### "API key not configured"

Make sure you've entered your Anthropic API key in the add-on configuration and restarted the add-on.

### Terminal not loading

1. Check the add-on logs for errors
2. Try restarting the add-on
3. Clear your browser cache

### Claude commands not working

1. Verify your API key is valid
2. Check you have sufficient API credits
3. Look at the add-on logs for error messages

### MCP not connecting to Home Assistant

1. Ensure `enable_mcp` is set to `true`
2. Restart the add-on after changing configuration
3. Check logs for MCP-related errors

## Security Notes

- Your API key is stored securely in Home Assistant's add-on configuration
- The add-on runs in an isolated container
- Network access is limited to what's necessary for Claude Code operation

## Support

For issues and feature requests, visit:
https://github.com/robsonfelix/claudecode-hass-integration/issues
