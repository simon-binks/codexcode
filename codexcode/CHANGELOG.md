# Changelog

All notable changes to this add-on are documented here.

## [1.3.0] - 2026-02-12

### Changed
- Renamed add-on metadata and branding from Claude Code to Codex Code.
- Renamed startup option `auto_update_claude` to `auto_update_codex`.
- Renamed AppArmor profile from `claudecode` to `codexcode`.

### Fixed
- Translation keys now match the active option schema (`auto_update_codex`).
- Updated localized descriptions to Codex/OpenAI-oriented wording.

### Refactored
- Moved long inline Docker startup logic into `/usr/local/bin/start.sh`.
- Simplified container startup command to `CMD ["/usr/local/bin/start.sh"]`.

### Removed
- Removed Claude CLI installation from the image build.
- Removed Claude-specific startup command invocations and aliases.

