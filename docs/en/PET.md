# Pet snippets

> Command-line snippet manager for all SetupVibe editions — v0.41.11

[Pet](https://github.com/knqyf263/pet) saves shell commands with descriptions,
tags and parameters. SetupVibe installs it after Harlequin, with `fzf` as its
interactive selector.

## Installation

| Platform | Installation |
| --- | --- |
| Desktop macOS, Linux and WSL | `brew install pet fzf`, using SetupVibe's existing Homebrew |
| Linux Server | Official Pet 1.0.1 binary in `~/.local/bin`; existing APT `fzf` |
| Omarchy | `omarchy pkg add pet-bin fzf` |
| Native Windows x64 | Official Pet 1.0.1 binary in `%USERPROFILE%\.setupvibe\bin`; existing WinGet `fzf` |

The shared `utils/install_pet.mjs` helper verifies the official release's
SHA-256 before extracting and installing Server/Windows binaries. It reuses
an existing matching version. Release downloads and validation files are
temporary. Homebrew retains its normal cache policy; Server and Omarchy keep
their package-manager policies without adding Homebrew. Omarchy installs only
missing commands.

Validation uses a temporary `PET_CONFIG_DIR`, because even `pet version` can
initialize configuration files. Existing snippets, editor settings, sync
credentials and shell bindings are preserved. Windows `-Uninstall` removes
the managed executable and helper while retaining Pet's user data.

## Usage

```bash
pet new
pet new --multiline
pet new -t
pet list
pet search
pet exec
pet edit
```

`pet new` asks for a command and description; `-t` also asks for tags.
`pet search` selects and prints a snippet; `pet exec` executes the selection.
`pet edit` uses the configured editor. Shell snippets must match their execution
shell: native Windows defaults to `cmd.exe`, with an optional `[General].cmd`
override in Pet's configuration.

By default, Unix stores configuration and snippets in `~/.config/pet`;
Windows uses `%APPDATA%\pet`. `PET_CONFIG_DIR` selects another location.
To share snippets between machines, configure `pet sync` with GitHub Gist or
GitLab through [Pet's synchronization options](https://github.com/knqyf263/pet#sync-snippets).
