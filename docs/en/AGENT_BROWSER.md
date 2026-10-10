# Agent Browser

> Desktop browser automation and agent integration — v0.41.11, local fork addition

The Unix Desktop installer adds `agent-browser` in step 14 and moves cleanup to
step 15. The Windows Desktop installer adds its own browser automation step.
The CLI, browser and official discovery skill are prepared for Codex and Claude
Code across projects. The Server and Omarchy installers do not include this step.

## Requirements and installation by platform

| Platform | Browser | Requirements and dependencies |
| --- | --- | --- |
| macOS 13+, Intel or Apple Silicon | Chrome for Testing through `agent-browser install` | Node.js 24 from the existing Homebrew step; no Linux libraries or Rust build required |
| Windows 11 22H2+, x64 | Chrome for Testing through `agent-browser.cmd install` | Node.js 24 from the official MSI; `agent-browser.cmd` and `skills.cmd` avoid restricted PowerShell script execution |
| Ubuntu 24.04+, Debian 12+, Zorin OS 18+, WSL; x86_64 | Chrome for Testing through `agent-browser install` | Node.js 24, APT browser libraries, fonts, Xvfb/Xauth and Vulkan |
| The same Linux systems; ARM64 | Chromium through Playwright's browser downloader | The same APT dependencies; no Snap daemon, global Playwright package, or test project |

Chrome currently requires macOS 13+. The other Unix Desktop steps still support
macOS 12, but the browser step reports a clear error there instead of claiming a
working browser. Windows on ARM remains outside SetupVibe's Windows support.

The upstream npm package requires Node.js 24+. Its native Rust CLI and browser
daemon do not require building Rust, installing pnpm, or running Playwright.
Playwright is used only to obtain Linux ARM64 Chromium because the upstream
`agent-browser install` rejects this platform. Downloads remain in the user's
`~/.cache/ms-playwright`. SetupVibe links the executable directory reported by
Playwright to `~/.agent-browser/browsers/chrome-setupvibe-arm64` so agent-browser
finds it even when Playwright changes its cache layout. The temporary downloader
package is removed on success or failure; user browser configuration is preserved.

Video recording with `agent-browser record` requires FFmpeg on `PATH`. The
existing Desktop base steps already install it on Linux and macOS; the Windows
utilities install and validate it as well.

## Linux dependencies and user ownership

The installer installs the library set from upstream `cli/src/install.rs`:

```text
libxcb-shm0 libx11-xcb1 libx11-6 libxcb1 libxext6 libxrandr2
libxcomposite1 libxcursor1 libxdamage1 libxfixes3 libxi6
libgtk-3-0 libpangocairo-1.0-0 libpango-1.0-0 libatk1.0-0
libcairo-gobject2 libcairo2 libgdk-pixbuf-2.0-0 libxrender1
libasound2 libfreetype6 libfontconfig1 libdbus-1-3 libnss3
libnss3-tools libnspr4 libatk-bridge2.0-0 libdrm2 libxkbcommon0
libatspi2.0-0 libcups2 libxshmfence1 libgbm1
fonts-noto-color-emoji fonts-noto-cjk fonts-freefont-ttf
```

It resolves available `t64` names after refreshing APT, including `libasound2t64`
and `libgtk-3-0t64` on Ubuntu 24.04. Installation uses `--no-remove` to abort
instead of removing existing packages. It also adds `xvfb`, `xauth`, `libvulkan1`
and `mesa-vulkan-drivers` for headed sessions without a display and WebGPU.

Only system libraries use `sys_do`. npm packages, browser downloads, skills and
validation run as `REAL_USER`, including when SetupVibe starts through `sudo`.
Linux npm globals remain under `~/.npm-global`; browser files never belong to
the invoking root account. Repeating setup reuses compatible downloads.

## Instructions for agents

SetupVibe installs the official discovery skill through the existing Skills CLI:

```bash
skills add vercel-labs/agent-browser --skill agent-browser --global --agent codex claude-code --yes
```

The discovery skill directs agents to instructions matching the installed CLI:

```bash
agent-browser skills get core
agent-browser skills get core --full
agent-browser skills list
```

Do not copy the usage guide from `node_modules`. The global skill is available
across projects; project-specific instructions can still refine its workflow.

## Validation and first use

The installer checks the CLI, bundled instructions and
`agent-browser doctor --offline`. Doctor launches an isolated scratch browser
session at `about:blank` and closes it; missing libraries or a failed launch
make the step fail. It does not enable the dashboard, a public listener, or a
persistent browser service.

After installation, restart your terminal and try:

```bash
agent-browser --version
agent-browser doctor --offline
agent-browser open https://example.com
agent-browser snapshot -i
agent-browser screenshot
agent-browser close
```

Use `--headed` for a visible browser. On Linux without a display, Xvfb is started
automatically for headed sessions. Re-snapshot after navigation or page changes
before reusing element references. Real sandbox restrictions must be diagnosed;
SetupVibe does not disable the browser sandbox by default.

On Windows, `-Uninstall` removes the npm CLI before removing Node.js. It preserves
browser caches, user sessions, credentials, and installed skills.

## Running this fork

The installation commands in the [project README](../../README.md#quick-start)
download directly from `C0R0NELL/setupvibe`, branch `main`. To test unpublished
changes, run `bash desktop.sh` from this checkout on Unix, or
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\desktop.ps1` from
this checkout on Windows. Remote commands include changes after they are pushed.

## Official references

- [agent-browser installation](https://agent-browser.dev/installation)
- [Native browser installer and Linux dependency list](https://github.com/vercel-labs/agent-browser/blob/main/cli/src/install.rs)
- [Linux ARM64 browser cache discovery](https://github.com/vercel-labs/agent-browser/blob/main/cli/src/native/cdp/chrome.rs)
- [Skills CLI installation options](https://github.com/vercel-labs/skills#options)
- [Playwright browser downloads](https://playwright.dev/docs/browsers)
- [Current Chrome system requirements](https://support.google.com/chrome/a/answer/7100626)
