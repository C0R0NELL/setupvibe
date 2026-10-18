# Terminal Browser

> Standalone browser for macOS, Linux, WSL and Linux servers — v0.41.11

SetupVibe installs [Terminal Browser](https://github.com/zenbu-labs/terminal-browser)
before Harlequin in Unix Desktop, Server and Omarchy. Native Windows does not
install it; use the Unix installer
inside WSL. No Herdr plugin is installed.

## Installation behavior

The shared helper uses the [official installer](https://terminal-browser.sh/install)
as the target user, with `TERMINAL_BROWSER_SKIP_SETUP=1` to skip interactive
onboarding. The upstream installer verifies its release archive's SHA-256.
The command is installed in `~/.local/bin`, with application files under
`~/.local/share/terminal-browser`. Shell profiles are unchanged.

Linux refreshes APT and installs `libnss3`, `libgtk-3-0`, `libasound2` and
`libgbm1`, selecting available `t64` variants without removing packages.
Omarchy uses `omarchy pkg add nss gtk3 alsa-lib mesa` instead of APT.
macOS uses the bundled libraries. The command, Linux shared libraries and
bundled runtime are validated without opening a browser.

A working managed installation is reused, preserving its version and running
browsers. Update explicitly with `terminal-browser upgrade`.

## Usage

```bash
terminal-browser open https://example.com
terminal-browser open http://localhost:3000
terminal-browser --version
```

The displaying terminal must support the Kitty graphics protocol, including
when connecting to a VPS over SSH. Installing system libraries alone does not
add graphics support to the local terminal. The browser is interactive; the
installer's runtime check does not validate graphics rendering.

For a browser installed locally, proxy requests through a remote machine with:

```bash
terminal-browser open --ssh user@server http://localhost:3000
```

## Browser zoom

On Linux or WSL, open the command palette with `Ctrl+K` or `Alt+K`; on macOS,
use `Cmd+P`. Choose **Zoom in** to enlarge the page, **Zoom UI in** for browser
controls, or **Reset zoom** to restore the page scale. The palette is useful
when the host terminal captures the usual zoom shortcuts.
