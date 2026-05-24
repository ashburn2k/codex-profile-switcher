# Codex Config Switcher

Native macOS utility for switching Codex work environments without manually renaming files.

## Why This Exists

Codex stores its active local settings in `~/.codex/config.toml` and its active
authentication state in `~/.codex/auth.json`. When you use Codex across multiple
work environments, switching contexts can turn into a manual rename-and-restore
routine that is easy to get wrong.

Codex Config Switcher was built to make that workflow safer and faster. It keeps
named environment profiles on disk, lets you activate one from a small native
macOS app, and backs up the current active files before each switch.

## How It Works

The app scans `~/.codex` for saved profiles, shows them in a simple picker, and
copies the selected profile's files into the active Codex locations. It does not
store credentials inside the app bundle or publish any profile data to the repo;
all config and auth files stay local on the machine running the app.

When relaunch is enabled, switching profiles also quits the running Codex app and
opens Codex again so the newly copied profile is loaded on startup.

You can also save the currently active Codex setup as a new named profile. New
profiles are written to `~/.codex/profiles/<profile-name>/`, which keeps each
environment's `config.toml` and `auth.json` together. To update only app
preferences such as appearance, select a profile and use **Save App Settings**.

## What It Switches

- Active config: `~/.codex/config.toml`
- Active auth: `~/.codex/auth.json`
- Codex app settings: selected files under `~/Library/Preferences/com.openai.codex.plist`
  and `~/Library/Application Support/Codex/`

Profiles can live in either format:

- Folder profiles: `~/.codex/profiles/<profile-name>/config.toml` and `auth.json`
- Folder profiles with app settings: `~/.codex/profiles/<profile-name>/app-settings/`
- Existing loose files: `~/.codex/config-<profile-name>.toml` and `auth-<profile-name>.json`

Before every switch, the app backs up the current active files to:

`~/.codex/profile-switcher-backups/<timestamp>/`

When a profile includes app settings, Codex is closed before those files are
restored so Chromium local storage, such as appearance preferences, is not
overwritten by a running app.

## Build

For the local development loop, use the project run script:

```sh
./script/build_and_run.sh
```

It regenerates the Xcode project when `xcodegen` is available, builds into
project-local `build/DerivedData`, clears generated bundle metadata that can
break local signing, signs the cleaned app, and launches it. Optional modes:
`--verify`, `--logs`, `--telemetry`, and `--debug`.

```sh
xcodegen generate
COPYFILE_DISABLE=1 /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project CodexConfigSwitcher.xcodeproj -scheme CodexConfigSwitcher -configuration Debug build
```

If local code signing reports resource fork or Finder information errors, remove
extended attributes from the generated app bundle and run code signing again.
