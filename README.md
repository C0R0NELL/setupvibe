# SetupVibe

> The ultimate cross-platform development environment setup script — v0.41.11

Installs and configures a development environment in one command, supporting Windows 11, macOS, major Linux distributions and Omarchy 4. The Windows Edition focuses on native utilities, Python, Node.js, selected native AI CLIs, and the WSL 2 base system. The Unix Desktop Edition includes complete language ecosystems and a broader AI toolkit, the Server Edition remains focused on operations tooling, and the Omarchy edition adds only the SetupVibe layer that is not already present in the operating system.

## Key Features

- **Administrator Setup:** Requests standard UAC elevation on Windows without changing the UAC policy; uses `sudo` only where required on macOS and Linux.
- **Safe Windows Servicing:** Asks before stopping competing installers, tries a normal stop before forcing remaining processes, runs `sfc.exe /scannow` afterward, rejects pending restarts, and validates the component store.
- **Reliable OpenSSH Installation:** Resolves the latest official x64 Win32-OpenSSH MSI directly from its GitHub release page without the releases API, force-installs the client and server, and configures `sshd` and TCP/22 independently of DISM, Features on Demand, WSUS, or Windows Update.
- **Native Package Management:** Uses WinGet and Chocolatey on Windows, with Homebrew or APT on Unix systems.
- **Native Windows Shell:** Keeps Windows PowerShell and PowerShell 7 profiles unchanged, without Starship, ZSH, automatic zoxide initialization, or persistent execution-policy changes; Unix editions retain ZSH, Oh My Zsh, and Starship.
- **Optimized Terminals:** Installs Windows Terminal on Windows and configures Tmux + TPM on Unix systems.
- **Lazy Tool Appearance:** Desktop installers enable Lazygit file icons and Nerd Fonts v3; installed Lazydocker also receives status icons, rounded borders, and an expanding focused side panel. Other settings and the first `config.yml.bak` are preserved. Select a Nerd Font in the terminal that displays the session.
- **Terminal Image Preview:** Installs [Chafa](https://hpjansson.org/chafa/download/) on Desktop and Server through APT, Homebrew, or WinGet, and validates its command after installation.
- **Environment Skill:** Desktop and Server distribute the shared `setupvibe-environment` skill to ten supported agent harnesses through Skills CLI. It helps agents choose installed tools for user requests, with commands, practical uses, and availability by edition.
- **Global Helper Scripts:** Installs Windows helper scripts in `%USERPROFILE%\.setupvibe\bin` and adds the directory to the user's `PATH`.
- **AI Runtime Foundation:** Installs and validates Python 3.14 directly from `python.org` and Node.js 24 LTS from the official `latest-v24.x` channel on `nodejs.org`, automatically repairs missing runtime files, and exposes `python`, `pip`, `node`, `npm`, and `npx` in the Windows machine `PATH` for Claude and Codex.
- **Native Windows AI CLIs:** Installs Claude Code through Anthropic's recommended native installer with its official npm package as a recovery path, Codex CLI through OpenAI's official standalone Windows installer, OpenCode CLI, and Google Antigravity CLI as `agy`, while preserving PowerShell profiles and restricted execution policies.
- **Agent Skills:** Installs and validates the [Vercel Labs Skills CLI](https://github.com/vercel-labs/skills) on Desktop, Windows, and Server editions.
- **Desktop Browser Automation:** Adds [agent-browser](https://github.com/vercel-labs/agent-browser), Chrome/Chromium, OS dependencies, and its official global skill for Codex and Claude on Unix Desktop and Windows. Linux ARM64 uses a compatible Chromium download; current Chrome requires macOS 13+. See the [browser guide](docs/en/AGENT_BROWSER.md).
- **Agent Multiplexer:** Installs and validates [Herdr](https://github.com/herdrdev/herdr) on the Unix Desktop and Server editions, with a dedicated [usage guide](docs/en/HERDR.md).
- **Terminal Browser:** Installs the standalone [Terminal Browser](docs/en/TERMINAL_BROWSER.md) on Unix Desktop (macOS, Linux and WSL), Server and Omarchy, including Linux libraries and command validation.
- **Terminal SQL Client:** Installs [Harlequin](docs/en/HARLEQUIN.md) with PostgreSQL and MySQL adapters through uv and Python 3.14 on all editions, validating its isolated environment without connecting to external databases.
- **Command Snippets:** Installs [Pet and fzf](docs/en/PET.md) on all editions, reusing Homebrew on Desktop/macOS/Linux/WSL and preserving saved snippets and configuration.
- **Unix Antigravity CLI:** Installs Google's Antigravity CLI as `agy` on the Unix Desktop edition, resolving and SHA-512-verifying its versioned release manifest directly (the official Unix bootstrapper does not forward `--skip-aliases`/`--skip-path` to its own `agy install` step) and running `agy install --skip-aliases --skip-path` explicitly so shell profiles stay untouched.
- **WSL 2 Ready:** Installs the WSL base without a Linux distribution and configures mirrored VPN/LAN networking and development optimizations on Windows 11.
- **Smart Privilege Elevation:** Uses `sudo` only where strictly necessary on macOS and Linux; most tools are installed in `$HOME/.local/bin`.
- **Global QR Code Generator:** Installs the PyPI `qrcode` package for the target user on macOS and Linux, exposing its `qr` command in the shell.
- **Auto-Update:** Automatically upgrades existing Homebrew packages during setup.
- **Modern Shell:** ZSH + Oh My Zsh + Starship with a curated set of plugins and aliases.
- **Optimized Tmux:** Pre-configured with TPM, intuitive keybindings, and window/pane numbering starting at 1.
- **Current Runtimes:** PHP 8.5, Ruby 3.4.10, Go 1.26.5, Python 3.14 on macOS, and Node.js 24 LTS.
- **AI-Ready Unix Editions:** Includes the latest AI CLI tools for developers on macOS, Linux, and WSL.
- **Omarchy 4 Edition:** Preserves Omarchy defaults and adds SetupVibe through `omarchy.sh`, without removing operating-system packages or replacing its shell configuration.

## Documentation

|                        | Link                                                       |
| ---------------------- | ---------------------------------------------------------- |
| Overview               | [docs/README.md](docs/README.md)                           |
| Desktop Edition        | [docs/desktop/README.md](docs/desktop/README.md)           |
| Windows Edition (Beta) | [docs/windows/README.md](docs/windows/README.md)           |
| Server Edition         | [docs/server/README.md](docs/server/README.md)             |
| Omarchy 4 Edition      | [docs/omarchy/README.md](docs/omarchy/README.md)           |
| Debian Engineering     | [DEBIAN.md](DEBIAN.md)                                     |
| Tmux Guide             | [docs/desktop/en/tmux.md](docs/desktop/en/tmux.md)         |
| PM2 Guide              | [docs/desktop/en/pm2.md](docs/desktop/en/pm2.md)           |

## Brand

The official light and dark logos, color tokens, local webfonts, brand
description, and voice guide live in [`brand/`](brand/). Use the SVG assets
and semantic tokens by default, then follow the publication checklist before
creating public material.

## Quick Start

The commands below download published files from
[`C0R0NELL/setupvibe`](https://github.com/C0R0NELL/setupvibe), branch `main`.
Run scripts from the local checkout to test changes before publishing them.

### Desktop (macOS, Linux & WSL)

```bash
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/desktop.sh | bash
```

### Windows Desktop (Beta)

Run the Windows utility installer directly from this fork's `main` branch. It requests administrator access through the standard UAC prompt without changing the UAC policy.

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/desktop.ps1 | iex
```

See the [Windows installation guide](docs/windows/README.md) for local installation, verification, logs, restart options, and the `-Uninstall` mode.

### Server (Linux only)

```bash
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/server.sh | bash
```

To initialize Docker Swarm automatically after setup:

```bash
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/server.sh | bash -s -- --manager
```

Add `--yes` for unattended installation or `--advertise-addr ADDRESS` to choose the Swarm address or interface explicitly.

### Omarchy 4

```bash
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/omarchy.sh | bash
```

Use `bash omarchy.sh --yes` for an unattended local run. See the [Omarchy
installation guide](docs/omarchy/README.md) for the preserved components and
the added layer.

## General Notes

### Agent Environment Skill

Desktop (Unix and Windows) and Server install the product skill from
[`skills/setupvibe-environment/SKILL.md`](skills/setupvibe-environment/SKILL.md)
for Codex, Claude Code, OpenCode, Grok Build, Kimi Code CLI, Gemini CLI, Cursor,
GitHub Copilot, Antigravity CLI, and Amp. It is available across projects under
each harness's user skill directory, even if the harness is installed later.
Its tables cover installed utilities for images, browser automation, files,
containers, diagnostics, sessions, and agent tooling, with practical commands
and availability by edition. Ordinary language runtimes are omitted.
See [installation, locations, and update behavior](docs/en/ENVIRONMENT_SKILL.md).

### Images in the Terminal

Desktop and Server install Chafa for image previews inside the terminal.
Linux and WSL use APT, macOS uses Homebrew, and Windows uses the WinGet package
`hpjansson.Chafa`. Windows `-Uninstall` also removes this package.

```bash
chafa "image.png"

# Character output for terminals without an image protocol, SSH, or Tmux
chafa --format symbols "image.png"
```

The default rendering depends on the terminal's supported image protocols;
`--format symbols` uses text characters. See the [official manual](https://hpjansson.org/chafa/man/).

### Herdr Plugins

After SetupVibe finishes, install the desired Herdr plugins manually from your
user terminal. This fork keeps the following list as a post-installation
reference for Linux, macOS, and WSL:

| Plugin | Purpose | Main requirements |
| --- | --- | --- |
| [Account Hub](https://github.com/C0R0NELL/herdr-account-hub) | Switch Codex/Claude accounts and check usage; Claude support is in beta. | Python 3.11+ and the relevant agent CLI. |
| [Herdr Plus](https://github.com/cloudmanic/herdr-plus) | Workspace templates and quick actions. | Herdr 0.7.0+; Go is optional on Linux/macOS. |
| [Herdr Web UI](https://github.com/devswha/herdr-web-ui) | Access agent chats and terminals from a browser or phone. | Herdr 0.9.0+, Bun 1.4+, and Node.js 18+ on Linux/macOS. |
| [Herdr Board](https://github.com/nelsonPires5/herdr-board) | Kanban cards that dispatch prompts to agents. | Herdr 0.9.0+ with socket protocol 22, Git, and Rust/Cargo. |
| [Agents Sidebar](https://github.com/C0R0NELL/herdr-agents-sidebar) | Group native sidebar agents by machine and workspace. | Linux, Herdr 0.9.3+, and Python 3.11+ with curses. |
| [Herdr Plugin Manager](https://github.com/speardragon/herdr-plugin-manager) | Browse, install, update, and manage plugins from a popup. | Herdr 0.7.4+, Bash, and Python 3. |
| [TTT](https://github.com/eugenioenko/ttt) | Terminal editor integrated into Herdr panes. | Herdr 0.7.0+, Git, and ripgrep for the full feature set. |

Check the linked READMEs for configuration, keybindings, and current
compatibility, then run the commands for the plugins you want:

```bash
herdr --version
herdr plugin install C0R0NELL/herdr-account-hub
herdr plugin install cloudmanic/herdr-plus
herdr plugin install devswha/herdr-web-ui
herdr plugin install nelsonPires5/herdr-board --ref v0.19.0
herdr plugin install C0R0NELL/herdr-agents-sidebar
herdr plugin install speardragon/herdr-plugin-manager
herdr plugin install eugenioenko/ttt/herdr-plugin
herdr plugin list
```

The TTT plugin lives in the repository's `herdr-plugin` subdirectory and
installs the editor binary if it is missing from `PATH`. Web UI's repository
also provides an installer for missing prerequisites. After installing Agents
Sidebar, choose **Apply sidebar** in the Plugin Manager to activate it in the
current session. See the [SetupVibe Herdr guide](docs/en/HERDR.md) for sessions
and shortcuts.

## Contributing

We welcome contributions of all sizes! Please read our [Contribution Guide](CONTRIBUTING.md) to get started.

---

Maintained by [promovaweb.com](https://promovaweb.com) · Licensed under [GPL-3.0](LICENSE)

---
