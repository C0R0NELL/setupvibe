# AGENTS.md

This file provides instructions and context for OpenAI Codex when working with the **SetupVibe** repository.

## What This Project Is

**SetupVibe** is a cross-platform automated development environment setup script (v0.41.11). It installs and configures a complete developer toolkit in one command, supporting Windows 11 22H2+, macOS 12+, Linux (Ubuntu 24.04+, Debian 12+, Zorin OS 18+) and Omarchy 4 on Arch Linux x86_64.

There are four editions:

- `desktop.sh` — macOS, Linux desktops, and WSL; full stack including language ecosystems, GUI tools, and AI CLIs
- `desktop.ps1` — native x64 Windows 11 22H2+ (Beta); Windows utilities, Python 3.14, Node.js 24 LTS, Claude Code, Codex CLI, Antigravity CLI, and the WSL 2 base without a Linux distribution, frameworks, or runtime managers
- `server.sh` — Linux-only; lean install focused on DevOps tools, Docker, shell, and monitoring
- `omarchy.sh` — Omarchy 4 on Arch Linux x86_64; additive SetupVibe layer that preserves Omarchy defaults and configuration

## How to Run

Scripts are executed directly, without a build step:

```bash
# Run locally
bash desktop.sh
bash server.sh
bash omarchy.sh

# Or via curl from this fork
curl -fsSL https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/desktop.sh | bash
```

```powershell
# Run directly from this fork; it requests standard UAC elevation without changing the UAC policy
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/C0R0NELL/setupvibe/main/desktop.ps1 | iex

# Or run a local copy
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1

# Remove every utility and configuration managed by the Windows Edition
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1 -Uninstall
```

To test changes to a script, run it directly on a target machine or VM.

Run `python3 tests/test_desktop_stdin.py` for the focused Desktop input-stream
regression checks. They exercise the real step runner without installing tools
or changing services; they do not replace full installer integration tests.

Run `python3 tests/test_omarchy_integrations.py` for isolated Omarchy checks of
the real helper functions, target-user downloads, sudo PATH, configuration
preservation and failure reporting. Package managers and the browser are
simulated; these checks do not replace a full Omarchy/TryOmarchy installation.

### Required Debian Context

Before changing, investigating, or testing `desktop.sh`, `server.sh`, Linux
configuration files, or Linux documentation, read [`DEBIAN.md`](DEBIAN.md)
completely. It is the required supplemental context for Linux implementation,
privilege handling, container integration tests, and known Debian constraints.
Update it whenever a real Linux test reveals a new requirement or limitation.

## Architecture

### Script Structure

Both `desktop.sh` and `server.sh` follow a numbered-step pattern (functions prefixed with `step_NN_`). Each step installs a logical group of tools. The scripts:

1. Detect OS, distro, and CPU architecture (`x86_64` vs `arm64/aarch64`)
2. Detect how the script was invoked (as root, via `sudo`, or as normal user) to correctly identify `$REAL_USER` and `$REAL_HOME`
3. Use `sudo` only where elevated privileges are required; everything else installs into `$HOME/.local/bin`
4. Clean up legacy APT repository entries before adding new ones (avoids GPG signature errors)

### Windows Script Structure

Before changing `desktop.ps1`, read the
[Windows guide](docs/windows/en/README.md), including servicing and uninstall
behavior. Keep these edition boundaries:

- Support x64 Windows 11 22H2+ only. Use standard UAC elevation with the same
  signed-in account and retain the servicing preflight, consent before stopping
  competing installers, and logs under `C:\ProgramData\SetupVibe\Logs`.
- Install only Python 3.14 and Node.js 24 LTS as programming runtimes, plus uv
  solely for Harlequin. Prepare WSL 2 without a Linux distribution; configure
  installed distributions separately with `desktop.sh`.
- Use signed official installers for OpenSSH, Python and Node.js. Resolve
  OpenSSH through its latest release page, without Features on Demand or the
  releases API; obtain Python from `python.org` and Node.js from the official
  `latest-v24.x` channel, without WinGet or Chocolatey. Verify Node.js against
  its official SHA-256 and retain OpenSSH Client/Server repair and validation.
- Keep Claude Code, Codex CLI and Antigravity CLI on their official native
  installation paths, with command validation. Antigravity uses
  `--skip-aliases --skip-path`.
- Preserve PowerShell profile bytes, execution policy, user Starship settings
  and Windows Terminal's default profile. Do not install Starship or ZSH;
  zoxide remains an uninitialized utility. Remove only recognized legacy
  SetupVibe profile blocks.
- Track ownership of managed files and environment changes. Normalize,
  deduplicate, broadcast and validate persistent `PATH` updates. Uninstall must
  restore prior WSL/firewall states and preserve distributions, credentials,
  skills, user settings and unrelated files.

This fork is maintained in `C0R0NELL/setupvibe` on `main`. Installation commands,
configuration downloads, helper scripts, Windows elevation handoff, restart,
uninstall, and setup aliases must use direct GitHub raw URLs from this fork's
`main` branch. Use another branch only when explicitly testing that branch.
Keep the Codex and Claude skills aligned with this source policy.

### Tool installation guides

Use the existing shared helpers and read the relevant guide before changing a
tool. Platform support, installation commands, pinned releases and validation
details belong in those guides and implementations.

| Component | Implementation and guide |
| --- | --- |
| Browser automation | Edition browser steps; [Agent Browser](docs/en/AGENT_BROWSER.md) |
| Lazy tool appearance | `utils/configure_lazy_ui.py`; [Desktop step 8](docs/desktop/en/README.md#step-8--modern-unix-tools) |
| Terminal Browser | `utils/install_terminal_browser.sh`; [guide](docs/en/TERMINAL_BROWSER.md) |
| Harlequin | `utils/install_harlequin.sh`, `utils/validate_harlequin.py`; [guide](docs/en/HARLEQUIN.md) |
| Pet snippets | `utils/install_pet.mjs` for Server, Windows and Omarchy; [guide](docs/en/PET.md) |
| Redis TUI | `utils/install_redis_tui.sh`; [guide](docs/en/REDIS_TUI.md) |
| Yazi and ya | Edition package-manager steps; [guide](docs/en/YAZI.md) |

Browser automation must validate the native CLI, `agent-browser skills get core`
and a real headless launch with `agent-browser doctor --offline`. Install the
official discovery skill for Codex and Claude Code, rather than copying a guide
from `node_modules`. Linux ARM64 needs the Playwright browser downloader;
see `DEBIAN.md` for cache discovery and system dependencies.

Keep validation isolated from user data and external databases. In particular,
Pet checks need a temporary `PET_CONFIG_DIR`, since even `pet version` creates
configuration files. Lazy UI changes must preserve unrelated settings, encoding,
line endings and the first backup, and skip unsupported YAML layouts.

### Distributed environment skill

`skills/setupvibe-environment/SKILL.md` is the single source for the product
skill shipped by all four editions. Keep its command examples, uses, runtimes
and edition availability aligned with the installers. Distinguish executables
from aliases and isolated runtimes from system interpreters.

This product skill is separate from the repository's maintenance skills; do
not duplicate it into `.codex/skills` or `.claude/skills`.

Distribute through `utils/install_environment_skill.mjs` as the target user,
using the local source in checkouts and this fork's raw `main` source remotely.
Preserve unrelated skills and agent configuration, including during Windows
uninstall. Follow the [distribution guide](docs/en/ENVIRONMENT_SKILL.md) for
harness targets, native roots, location overrides and partial-failure handling.

### `omarchy.sh`

Omarchy 4 owns the existing shell, prompt, aliases, Tmux, Docker, mise,
runtimes, fonts, modern Unix tools, Neovim, Herdr and main AI CLIs.
SetupVibe adds missing components through `omarchy pkg add`, user files under
`~/.config/setupvibe` and `~/.setupvibe`, and additive shell integration.
Do not use APT or Homebrew, install ZSH/Oh My Zsh, replace Omarchy configuration
files, or remove packages.

Reuse the user's mise runtimes and Node.js 24+; preserve the managed PATH
through sudo. Downloads, temporary files and user-space tools must belong to
the target user.

Docker operations must target a local endpoint and preserve configuration and
data. Start the native daemon only for its default local socket; preserve
custom and rootless setups.

`omarchy.sh --repair` runs only PHP ZIP, Ruby/Rails and Docker/Portainer checks.
Read the [Omarchy guide](docs/omarchy/README.md) for repair behavior and
configuration ownership.

### `docs/` Directory

| Path                        | Content                                                           |
| --------------------------- | ----------------------------------------------------------------- |
| `docs/README.md`            | Overview and comparison table of all editions                     |
| `docs/desktop/en/README.md` | Full desktop edition documentation (20 steps)                     |
| `docs/server/en/README.md`  | Server edition documentation (14 steps)                           |
| `docs/windows/en/README.md` | Windows edition (Beta) documentation                              |
| `docs/omarchy/README.md`    | Omarchy 4 additive edition documentation                          |
| `docs/en/EXECUTABLES.md`    | Executable helper script documentation (shared by Unix editions) |
| `docs/en/AGENT_BROWSER.md`  | Desktop browser automation, OS dependencies, and agent integration |
| `docs/en/ENVIRONMENT_SKILL.md` | Product environment skill, supported harnesses, and user skill roots |
| `docs/desktop/en/tmux.md`   | Tmux plugin and keybinding reference (shared by Unix editions)   |
| `docs/desktop/en/pm2.md`    | PM2 command and configuration reference (shared by Unix editions)|

### `brand/` Directory

[The brand guide](brand/README.md) is the entry point for normative visual
assets, tokens, typography and voice. Update the relevant source when a public
asset or brand rule changes, follow [the publication checklist](brand/checklist.md),
and do not create divergent logo copies.

### `conf/` Directory

Configuration files deployed by the scripts to the user's home directory:

| File | Deployed to | Purpose |
| --- | --- | --- |
| `tmux-desktop.conf` | `~/.tmux.conf` (desktop) | Tmux with TPM; 20+ plugins, onedark theme, mouse support, session persistence |
| `starship.toml` | `~/.config/starship.toml` (Desktop/Server); `~/.config/setupvibe/starship.toml` (new Omarchy configurations) | Shared Gruvbox Rainbow prompt with `user@hostname` over SSH; local checkouts use this file, remote runs download it from this fork's `main` |
| `tmux-server.conf` | `~/.tmux.conf` (server) | Lean tmux config for server environments |
| `zshrc-macos.zsh` | `~/.zshrc` (macOS) | Homebrew, Cargo, Composer, Go, Bun, rbenv paths |
| `zshrc-linux.zsh` | `~/.zshrc` (Linux desktop) | Linuxbrew paths, NPM, system aliases |
| `zshrc-server.zsh` | `~/.zshrc` (server) | Server-specific shell config |
| `ecosystem.config.js` | Used with PM2 | PM2 config for two app processes |

### `bin/` Directory

Executable helper scripts deployed by the installers to `~/.setupvibe/bin`:

| File | Deployed to | Purpose |
| --- | --- | --- |
| `ssh_copy_id` | `~/.setupvibe/bin/ssh_copy_id` | Copies the local public SSH key to a remote server using `--host`, `--user`, and optional `--pass` or hidden password prompt |

## Development Conventions

- Resolve the target user and home independently of the process UID. Use
  `user_do` for that user's files and commands and `sys_do` only for privileged
  operations. Preserve access to managed commands through sudo.
- For user-space tools, keep downloads and temporary files owned by the target
  user, verify published checksums, and validate commands in that user's environment.
- APT keys go in `/etc/apt/keyrings/`. Remove only recognized legacy SetupVibe
  sources before adding replacements; retain Server's lock waiting and retries.
- Approve only the necessary npm installation scripts, rather than enabling all
  dependency scripts.
- Preserve user data and unrelated configuration during installation, reruns
  and removal. Required failures must propagate instead of reporting success.
- When adding or removing a tool, review all four editions, their guides and
  the product skill's availability table. Document platform exclusions.

## Versioning

The version number is defined at the top of `desktop.sh`, `desktop.ps1`, `server.sh`, and `omarchy.sh`. **Whenever a version is changed, it must be updated in ALL related files to maintain consistency**, including:

- `desktop.sh` (version variable)
- `desktop.ps1` (version variable)
- `server.sh` (version variable)
- `omarchy.sh` (version variable)
- `CHANGELOG.md` (new entry)
- `README.md` (root project overview)
- `AGENTS.md` (project overview)
- `CLAUDE.md` (project overview)
- All `README.md` files in the `docs/` directory and its subfolders.
- Any other documentation referring to the current version.

## Markdown Standards

All `.md` files in this project must conform to the rules defined in [`MARKDOWN.md`](MARKDOWN.md). That file is the single source of truth for formatting rules, markdownlint rule IDs, configuration, and examples.

The linting configuration is in [`.markdownlint.json`](.markdownlint.json) at the project root.

## AI Context and Skill Synchronization

**`AGENTS.md` and `CLAUDE.md` are the two primary AI context files for this project.** They must always be kept in sync with each other for shared project rules.

### Context Rule

Whenever either file is modified — to add a new convention, update architecture information, change a rule, or correct an error — the **same shared change must be applied to the other file** before the task is considered complete.

Keep recurring maintenance rules and documentation pointers here. Record
corrections in the changelog and implementation details in code, tests and
focused guides.

### Skill Rule

Codex and Claude maintain separate skill folders:

- `.codex/skills` — Codex-specific skills using Codex terminology, tools, and workflows.
- `.claude/skills` — Claude-specific skills using Claude Code terminology, tools, and workflows.

Whenever a skill is added, removed, renamed, or materially changed in one folder, the equivalent skill must be updated in the other folder. The workflows should stay functionally aligned, but platform-specific instructions must remain native to each agent.

### Scope

This synchronization rule covers:

- Project overview and version references
- Architecture descriptions and step counts
- Key scripting patterns and conventions
- Versioning policy (the list of files to update)
- Markdown standards reference
- Skill inventory and cross-agent skill compatibility rules
- Any new global rule or policy added to one file

### What is NOT synchronized

Each file may contain sections specific to its target agent (tool-specific invocation syntax, skill references, etc.). Those sections are intentionally different and must not be overwritten.

No third AI agent context is maintained for this repository. Do not add extra agent context files, skill folders, or synchronization requirements unless the project explicitly adopts that agent.

---
