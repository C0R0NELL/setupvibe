# Yazi

> Terminal file manager for all SetupVibe editions — v0.41.11

[Yazi](https://yazi-rs.github.io/docs/installation/) provides an interactive
file manager and the companion `ya` CLI for its utilities and package manager.
SetupVibe validates both executables with `--version` without opening the
interface or changing user settings.

## Installation

| Edition | Method |
| --- | --- |
| Desktop macOS, Linux and WSL | `brew install yazi`, through SetupVibe's existing user Homebrew |
| Linux Server | Official Yazi APT repository, stable channel when no official source exists |
| Omarchy | Existing `yazi`/`ya`, or `omarchy pkg add yazi` when missing |
| Native Windows x64 | WinGet `sxyazi.yazi`; includes `yazi.exe` and `ya.exe` |

Desktop installs Yazi after Redis TUI and before final cleanup. It supports
the installer's Intel/Apple Silicon macOS and x86_64/ARM64 Linux/WSL targets.
Homebrew's availability of prebuilt packages depends on the macOS release;
older systems may build from source. Server and Omarchy keep their native
package managers without adding Homebrew.

Server uses APT's repository signature and package checksum validation. It
reuses an existing official source, otherwise adds the stable channel with a
key under `/etc/apt/keyrings`. Lock waiting and retries remain active. It
installs only Yazi and required dependencies, preserving existing optional tools.

On Windows, Git for Windows supplies the Unicode-compatible `file.exe` used
for file type detection. SetupVibe preserves a valid `YAZI_FILE_ONE` setting;
otherwise it sets the user variable to Git's executable and records the prior
value. `-Uninstall` restores that value if it is still managed, removes the
WinGet package and preserves Yazi configuration and plugins.

## Usage

```bash
yazi --version
ya --version
ya --help
yazi
yazi /path/to/folder
```

The last two commands open the interactive file manager. Preview support
depends on the displaying terminal and optional helper tools. SetupVibe reuses
its installed tools and fonts; it does not replace shell bindings, editor
associations, Yazi configuration, themes or plugins. Windows and WSL have
separate installations.

See the [quick start](https://yazi-rs.github.io/docs/quick-start/) for navigation
and the [configuration guide](https://yazi-rs.github.io/docs/configuration/overview/)
for customization.
