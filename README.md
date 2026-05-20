# Codex Config Switcher

Native macOS utility for switching Codex work environments without manually renaming files.

## What It Switches

- Active config: `~/.codex/config.toml`
- Active auth: `~/.codex/auth.json`

Profiles can live in either format:

- Folder profiles: `~/.codex/profiles/<profile-name>/config.toml` and `auth.json`
- Existing loose files: `~/.codex/config-<profile-name>.toml` and `auth-<profile-name>.json`

Before every switch, the app backs up the current active files to:

`~/.codex/profile-switcher-backups/<timestamp>/`

## Build

```sh
xcodegen generate
COPYFILE_DISABLE=1 /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project CodexConfigSwitcher.xcodeproj -scheme CodexConfigSwitcher -configuration Debug build
```

If local code signing reports resource fork or Finder information errors, remove
extended attributes from the generated app bundle and run code signing again.
