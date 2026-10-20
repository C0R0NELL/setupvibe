# Redis TUI

> Terminal client for Redis on all SetupVibe editions — v0.41.11

[Redis TUI](https://github.com/davidbudnick/redis-tui) browses Redis keys,
previews values and TTLs, edits data and displays database metrics. It runs
as a standalone terminal interface. SetupVibe installs the client after Pet;
it does not install or start a Redis server.

## Platforms and installation

| Platform | Installation |
| --- | --- |
| Desktop Linux and WSL; Linux Server | Official native installer, x86_64 or ARM64 |
| Desktop macOS | Official native installer, Intel or Apple Silicon |
| Omarchy | Official native installer, x86_64; no additional system packages |
| Native Windows | Official Redis TUI 1.0.47 x64 ZIP, verified against the published SHA-256 |

Unix editions share `utils/install_redis_tui.sh`. The helper runs the official
installer as the target user, including when SetupVibe runs through sudo,
and installs the verified binary in `~/.local/bin`. No Go installation or
Homebrew tap is needed. The equivalent manual command is:

```bash
curl -fsSL https://raw.githubusercontent.com/davidbudnick/redis-tui/main/install.sh | bash
```

Windows uses `%USERPROFILE%\.setupvibe\bin\redis-tui.exe`, already on the
managed user `PATH`. Windows and WSL have separate installations.

Working managed installations are reused. Fresh binaries pass `--version`
and `--help` before replacing the managed command. Downloads are temporary
and removed on success or failure. The checks do not open the interface,
load saved connections or contact a database. Shell profiles are unchanged.

## Usage

```bash
redis-tui --version
redis-tui --help
redis-tui
redis-tui --host localhost --port 6379
redis-tui --host redis.example.com --tls
```

The last three commands open the interactive client. Without a host, it shows
the connection manager. Press `?` inside the interface for shortcuts.

User configuration remains in `~/.config/redis-tui/config.json`, including on
Windows under `%USERPROFILE%\.config\redis-tui\config.json`. SetupVibe does
not create or replace this file. Windows `-Uninstall` removes only the managed
executable, preserving saved connections. To update an existing installation,
use `redis-tui --update`.
