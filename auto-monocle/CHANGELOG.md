# Changelog

All notable changes to this project will be documented in this file.

## [0.1.7] - 2026-01-14

### Added
- Multi-method auto-discovery for RTSP URLs:
  1. go2rtc streams (HA built-in or standalone)
  2. UniFi Protect integration (query config entries + device registry)
  3. Camera entity attributes (stream_source, rtsp_url, etc.)
- Query HA config entries API for UniFi Protect NVR IP
- Query HA device registry for camera IDs
- Construct RTSP URLs from NVR IP + camera IDs

## [0.1.5] - 2026-01-14

### Fixed
- Write token to monocle.token file (required by gateway)
- Remove token from JSON config and logs (security)
- Don't print config file to logs

## [0.1.4] - 2026-01-14

### Fixed
- Use bashio for proper HA add-on integration (fixes SUPERVISOR_TOKEN issue)
- Auto-restart Monocle Gateway when camera config changes (hash-based detection)

## [0.1.3] - 2026-01-14

### Fixed
- Use pip to install requests (Alpine py3-requests is for Python 3.12, base image has 3.13)

## [0.1.2] - 2026-01-14

### Fixed
- Remove --strip-components=1 from tar (tarball has no subdirectory)

## [0.1.1] - 2026-01-14

### Fixed
- Fixed Monocle Gateway download URL (use alpine-x64/alpine-arm64 builds)

## [0.1.0] - 2026-01-14

### Added
- Initial release
- Auto-discover cameras from Home Assistant
- Support for UniFi Protect cameras
- Support for generic camera integration
- Periodic camera list refresh
- Camera name filters
- Monocle Gateway integration
