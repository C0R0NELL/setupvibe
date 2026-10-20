# SetupVibe Windows Edition (Beta)

> Native Windows development environment guides — v0.41.11

The Windows Edition includes the Vercel Labs Skills CLI and [agent-browser with Chrome for Testing](../en/AGENT_BROWSER.md) alongside its native utilities and selected AI CLIs. The official browser skill is installed globally for Codex and Claude Code.

[Harlequin](../en/HARLEQUIN.md) is installed with PostgreSQL and MySQL adapters
through uv, using the existing Python 3.14 installation.

[Pet snippets](../en/PET.md) uses the official Windows binary and the existing
fzf selector. User snippets are preserved during installation and removal.

[Redis TUI](../en/REDIS_TUI.md) follows Pet using the official x64 ZIP with
SHA-256 verification, preserving saved connections during installation and removal.

[Yazi and ya](../en/YAZI.md) use WinGet and Git for Windows file type detection,
with a reversible `YAZI_FILE_ONE` setting and preserved user configuration.

Choose your language:

- [English](en/README.md)
- [Português](pt-br/README.md)
- [Français](fr/README.md)
- [Español](es/README.md)
