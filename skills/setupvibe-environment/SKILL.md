---
name: setupvibe-environment
description: Consult the tools already installed in this environment to choose suitable commands and carry out tasks according to the user's request.
---

# SetupVibe Environment

Use this inventory to select an installed tool for the user's task or suggest
a command they can run. It covers useful utilities supplied by SetupVibe;
ordinary language runtimes such as Python and Node.js are omitted.

## Availability

- **D:** Unix Desktop, including macOS, Linux and WSL configured with `desktop.sh`.
- **S:** Linux Server configured with `server.sh`.
- **W:** Native Windows configured with `desktop.ps1`.
- **Linux:** Linux Desktop, WSL and Server; excludes macOS and native Windows.

The tables describe each installer's tool list. Check the relevant executable
in the current session with `command -v TOOL` on Unix or `Get-Command TOOL` in
PowerShell before relying on it. Windows and WSL have separate installations.
An installed CLI may still need the user's authentication or service startup.

Prefer executable names over shell aliases in automation. Commands marked
**interactive** open a terminal interface and are useful when the user wants
to work in that interface; use commands that print results for agent inspection.

## Images, media and browser tasks

| Tool | Command or example | Use for | Editions |
| --- | --- | --- | --- |
| Chafa | `chafa "image.png"` | Preview an image directly in the terminal. | D, S, W |
| Chafa, character output | `chafa --format symbols "image.png"` | Preview images over SSH or inside Tmux without an image protocol. | D, S, W |
| ImageMagick | `magick identify "image.png"` (v7) or `identify "image.png"` (v6) | Inspect dimensions and format; resize, convert or compose images with `magick` (v7) or `convert` (v6). | D, W |
| FFmpeg / FFprobe | `ffprobe "video.mp4"`; `ffmpeg -i "input.mov" "output.mp4"` | Inspect, convert or extract audio/video; support browser recordings. | D, W |
| QR code generator | `qr --output=qr.png https://example.com` | Generate a QR image from text or a URL; `qr --help` lists output options. | D |
| agent-browser | `agent-browser skills get core`; `agent-browser open https://example.com`; `agent-browser snapshot -i` | Automate a browser, inspect pages, fill forms and capture screenshots. | D, W; macOS 13+ |

For agent-browser, read `skills get core` for instructions matching the installed
version, and close the session with `agent-browser close` when finished. On
Windows PowerShell, use `agent-browser.cmd` to avoid execution-policy issues.
Linux Desktop already includes browser libraries, fonts, Xvfb/Xauth and Vulkan;
Linux ARM64 uses the Chromium prepared by the installer.

## Files, search and structured data

| Tool | Command or example | Use for | Editions |
| --- | --- | --- | --- |
| Ripgrep | `rg -n "pattern" .`; `rg --files` | Search source text or list project files quickly. | D, W |
| fd | `fd '\.png$' .` | Find files by name or extension. | D, W |
| bat | `bat --paging=never "file.txt"` | Read files with syntax highlighting without opening a pager. | D, W |
| eza | `eza -la`; `eza --tree --level=2` | Inspect directory contents or a compact directory tree. | D, W |
| fzf | `fzf` (**interactive**); `fzf --filter="term"` | Select from a list interactively, or filter newline-separated input without a TUI. | D, S, W |
| jq | `jq '.items[]' "data.json"` | Query, transform and format JSON. | D, S, W |
| Glow | `glow "README.md"` | Render Markdown for reading in the terminal. | D, W |
| tldr via tlrc | `tldr docker` | Look up short practical command examples. The executable is `tldr`, not `tlrc`. | D, W |
| Zoxide | `zoxide query project` | Find a previously visited directory; `z project` navigates in configured Unix ZSH sessions. Windows installs the CLI without shell initialization. | D, S, W |
| Neovim | `nvim "file.txt"` (**interactive**) | Edit files in a terminal editor. | D, W |
| Wget | `wget -O "download.zip" https://example.com/download.zip` | Download a file to a chosen path; use `wget.exe` on PowerShell to avoid its `wget` alias. | D, S, W |
| rsync | `rsync -av --dry-run "source/" "destination/"` | Preview file synchronization locally or over SSH before applying it. | Linux; macOS system utility |
| 7-Zip | `7z l "archive.zip"` | List archive contents and extract archives with `7z x`. | W |

## Git, containers and infrastructure

| Tool | Command or example | Use for | Editions |
| --- | --- | --- | --- |
| GitHub CLI | `gh repo view`; `gh pr list`; `gh issue list` | Inspect GitHub repositories, pull requests and issues from the current project. | D, S, W |
| Lazygit | `lazygit` (**interactive**) | Review diffs, stage changes and manage Git history in a TUI. | D, W |
| Docker | `docker ps`; `docker logs --tail 100 CONTAINER`; `docker stats --no-stream` | Inspect containers, logs and resource usage. | D, S |
| Docker Compose | `docker compose ps`; `docker compose config` | Inspect a project's services and validate its Compose configuration. | D, S |
| Docker Buildx | `docker buildx ls` | Inspect builders for container image builds. | D, S |
| Docker Swarm | `docker info`; `docker service ls`; `docker stack ls` | Inspect Swarm services and stacks when the host is a manager. Server initialization is optional through `--manager`. | D, S; active Swarm required |
| Portainer CE | `docker compose -f "$HOME/.setupvibe/portainer-compose.yml" ps` | Inspect the Portainer instance managed by SetupVibe; its web UI uses HTTPS port 9443. | D, S |
| Lazydocker | `lazydocker` (**interactive**) | Inspect and manage Docker resources in a terminal dashboard. | D |
| ctop | `ctop` (**interactive**) | Monitor container CPU, memory and network usage in a TUI. | D, S |
| Ansible | `ansible-inventory -i hosts --list`; `ansible-playbook site.yml --syntax-check` | Inspect inventories and validate playbook syntax for infrastructure automation. | D, S |
| PM2 | `pm2 list`; `pm2 logs APP --lines 100 --nostream` | Inspect managed application processes and recent logs. | D |
| Cronboard | `cronboard` (**interactive**) | View and manage local cron jobs or remote crontabs through SSH. | D, S |
| crontab | `crontab -l` | Read the current user's scheduled jobs without opening Cronboard. | D, S |
| SSH helper (Unix) | `ssh_copy_id --host HOST --user USER` | Copy a local public SSH key to a remote user's authorized keys; prompts for the password. | D, S |
| SSH helper (Windows) | `ssh_copy_id USER@HOST -NoConnect` | Copy the public key and verify key authentication without opening an interactive SSH session. | W |

Cronboard has no `--help` or `--version`; those arguments still open its TUI.
In a noninteractive Unix shell, invoke the SSH helper as
`"$HOME/.setupvibe/bin/ssh_copy_id"` if its ZSH alias is unavailable. The
Windows launcher is `ssh_copy_id.cmd` and works as `ssh_copy_id`.

## System and network diagnostics

| Tool | Command or example | Use for | Editions |
| --- | --- | --- | --- |
| Fastfetch | `fastfetch` | Summarize the operating system, hardware and shell environment. | D, W |
| duf | `duf` | Inspect filesystem capacity and free space. | D, W |
| htop / btop | `htop`; `btop` (**interactive**) | Inspect processes, CPU and memory usage in terminal dashboards. | D, S |
| btop4win | `btop4win` (**interactive**) | Inspect native Windows processes and resource usage. | W |
| Glances | `glances` (**interactive**) | Inspect system, process, disk and network metrics together. | D, S |
| Tailscale | `tailscale status`; `tailscale ip` | Check private-network connectivity and the machine's Tailscale addresses. | D, S, W; macOS installs the app |
| Nmap | `nmap -sT -p 80,443 HOST` | Check the specified host's HTTP/HTTPS ports when requested. | D, S, W |
| MTR | `mtr --report --report-cycles 10 HOST` | Inspect routing hops, latency and packet loss. | D, S |
| gping | `gping HOST` (**interactive**) | Compare latency with a live graph. | D, W |
| Trippy | `trip HOST` (**interactive**) | Explore network paths and latency in a traceroute dashboard. The executable is `trip`, not `trippy`. | D, W |
| RustScan | `rustscan -a HOST` | Discover open ports on a specified host when requested. | D |
| Speedtest | `speedtest-cli` (Unix); `speedtest` (Windows) | Measure internet throughput with the CLI installed on that platform. | D, S, W |
| bandwhich | `bandwhich` (**interactive**) | Inspect network bandwidth by process and connection; may require packet-capture privileges. | D |
| DNS tools | `dig example.com`; `whois example.com` | Inspect DNS records and domain registration data. | Linux |
| ss | `ss -tulnp` | Find listening TCP/UDP ports and the associated processes when permitted. | Linux |
| tcpdump | `tcpdump -i any -c 20` | Capture a bounded packet sample for requested network troubleshooting; requires capture privileges. | Linux |
| iftop / nload | `iftop`; `nload` (**interactive**) | Inspect network traffic and bandwidth. | Linux |
| iotop / sysstat | `iotop` (**interactive**); `iostat` | Inspect process I/O and disk/CPU statistics; iotop may require elevated privileges. | Linux |
| systemd tools | `systemctl status SERVICE --no-pager`; `journalctl -u SERVICE -n 100 --no-pager` | Inspect Linux service state and recent service logs. | Linux with systemd |
| Windows service tools | `Get-Service sshd`; `Get-NetTCPConnection -State Listen` | Inspect Windows service status and listening TCP sockets. | W; built-in PowerShell commands |

## Sessions and agent tooling

**Herdr** is the user's usual workspace and is likely already open. Prefer
its existing session for persistent terminal work within the user's request
and authorization, preserving running processes and user focus. Use Tmux
when requested, already in use, or Herdr is unavailable; avoid nesting the two.

Control Herdr panes only when `HERDR_ENV=1`. Identify the context through
`HERDR_WORKSPACE_ID`, `HERDR_TAB_ID` and `HERDR_PANE_ID`, target the intended
pane explicitly, and consult `herdr --help` for command syntax. Outside Herdr,
use the available terminal or provide a command for the user to run.

To leave work running, detach with `Ctrl+B`, then `q`; run `herdr` to reconnect.
`herdr server stop` terminates the processes in its panes.

| Tool | Command or example | Use for | Editions |
| --- | --- | --- | --- |
| Herdr | `herdr` (**interactive**); `herdr config check` | Organize workspaces, tabs and panes with agent status; validate its configuration. | D, S |
| Tmux | `tmux new -s NAME`; `tmux ls`; `tmux attach -t NAME` | Manage persistent terminal sessions; new/attach are interactive. | D, S |
| Skills CLI | `skills list --global`; `skills find TERM` | Discover installed skills or search for skills relevant to a task; use `skills.cmd` in Windows PowerShell. | D, S, W |
| Spec-Kit | `specify check`; `specify init PROJECT` | Check prerequisites or initialize a specification-driven project when requested. | D |
| Agentlytics | `agentlytics` | Start the installed agent-usage dashboard when requested; it has no noninteractive `--version`. | D |
| mise | `mise ls` | Inspect installed development tool versions managed by mise. | D |
| Claude Code / Codex / OpenCode | `claude`; `codex`; `opencode` | Start the installed coding agent when the user wants a separate agent session. | D, S, W |
| GitHub Copilot CLI | `copilot` | Start the installed Copilot agent. | D, S |
| Kimi Code CLI | `kimi` | Start the installed Kimi agent. | D |
| Antigravity CLI | `agy` | Start the installed Antigravity agent. | D, W |
| Windows Terminal / WSL | `wt`; `wsl --list --verbose` | Open a terminal or inspect WSL distributions; the Windows installer prepares WSL without installing a distribution. | W |

Unix ZSH shortcuts include `tn NAME` (`tmux new -s NAME`), `ta NAME`
(`tmux attach -t NAME`), `tl` (`tmux ls`), `d` (`docker`), `dc`
(`docker compose`), and `cronb` (`cronboard`). They are shell aliases, not
standalone executables.

## Source guides

The inventory follows the [Unix Desktop](https://github.com/C0R0NELL/setupvibe/blob/main/docs/desktop/en/README.md),
[Server](https://github.com/C0R0NELL/setupvibe/blob/main/docs/server/en/README.md)
and [Windows](https://github.com/C0R0NELL/setupvibe/blob/main/docs/windows/en/README.md)
installers and documentation. For additional examples, consult the
[browser guide](https://github.com/C0R0NELL/setupvibe/blob/main/docs/en/AGENT_BROWSER.md),
[Herdr guide](https://github.com/C0R0NELL/setupvibe/blob/main/docs/en/HERDR.md),
[SSH helper guide](https://github.com/C0R0NELL/setupvibe/blob/main/docs/en/EXECUTABLES.md)
([Windows syntax](https://github.com/C0R0NELL/setupvibe/blob/main/utils/windows/ssh_copy_id/README.md))
or [alias reference](https://github.com/C0R0NELL/setupvibe/blob/main/docs/en/ALIAS.md)
when needed.
