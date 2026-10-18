# Harlequin

> SQL client for Unix Desktop, Server, Omarchy and native Windows — v0.41.11

SetupVibe installs [Harlequin](https://harlequin.sh/docs/getting-started) after
Terminal Browser on Unix and near the end on native Windows, followed by Pet. It includes
the PostgreSQL and MySQL/MariaDB adapters, alongside built-in DuckDB and SQLite.
It runs independently in a terminal; no Herdr plugin is required.

## Platforms and installation

The same command works in Bash, ZSH and PowerShell when `uv` is available:

```bash
uv tool install --python 3.14 'harlequin[postgres,mysql]'
```

In Windows Command Prompt (`cmd.exe`), use double quotes around the package.

The project recommends Python 3.14 because some dependencies do not yet support
3.15. The supported SetupVibe platforms are Linux/WSL on x86_64 and ARM64,
macOS on Intel and Apple Silicon, Omarchy x86_64, and native Windows x64.
These are separate installations; Windows and WSL do not share their tools.

Unix reuses `uv`, installs it through the official installer if missing, or
uses `omarchy pkg add uv` on Omarchy. Installation runs as the target user,
including through `sudo`, and exposes `harlequin` in `~/.local/bin`.
`uv` can download Python 3.14 for the isolated tool environment when needed;
the Linux system Python is preserved. Shell profiles are unchanged.

SetupVibe adds `--no-cache` to use a temporary download cache for this
installation, preserving existing uv caches. Installed runtimes and tools remain.

Windows installs `uv` through its [officially documented WinGet package](https://docs.astral.sh/uv/getting-started/installation/#winget)
`astral-sh.uv`. It explicitly selects SetupVibe's existing Python 3.14 executable
and disables Python downloads. Its managed tool environment is under
`%USERPROFILE%\.setupvibe\harlequin-tools`, with the executable in
`%USERPROFILE%\.setupvibe\bin`, already on the user `PATH`. The `-Uninstall`
mode removes this environment before Python and uv, preserving user database
profiles and unrelated uv environments. Temporary environment overrides are
restored after installation or failure.

On Windows, the first interactive launch may download an IANA timezone
database, as described in the [official troubleshooting guide](https://harlequin.sh/docs/troubleshooting/timezone-windows).
Do not disable that download by default.

## Usage

```bash
harlequin --version
harlequin --help
hsql --help
harlequin -a sqlite example.db
harlequin -a postgres -h localhost -p 5432 -U user -d database
harlequin -a mysql -h localhost -p 3306 -U user --database database
```

The last three commands open the interactive client. Supply credentials using
your normal connection settings or [Harlequin profiles](https://harlequin.sh/docs/config-file/creating-config).
The [PostgreSQL](https://harlequin.sh/docs/postgres) and
[MySQL/MariaDB](https://harlequin.sh/docs/mysql) guides document their options;
the MySQL adapter uses individual options rather than a DSN.

SetupVibe validates the Python version, loads both adapters and drivers,
executes a local in-memory DuckDB query, and checks `--version` and `--help`.
These checks do not contact external databases or open the interactive client.

The package also provides `hsql` for noninteractive SQL work; consult
`hsql --help` for commands and connection options matching the installed version.
