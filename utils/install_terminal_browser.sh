#!/bin/bash

# Sourced by the Unix installers; uses their privilege and download helpers.
setupvibe_install_terminal_browser() (
    set -euo pipefail

    local platform
    local package
    local temporary_dir
    local missing_libraries
    local binary="$REAL_HOME/.local/bin/terminal-browser"
    local engine="$REAL_HOME/.local/share/terminal-browser/app/electron/pixel"
    local -a packages=(libnss3 libgtk-3-0 libasound2 libgbm1)
    local -a resolved_packages=()

    platform=$(uname -s)
    case "$platform-$(uname -m)" in
        Darwin-arm64|Darwin-x86_64|Linux-x86_64|Linux-amd64|Linux-aarch64|Linux-arm64) ;;
        *)
            echo "Error: Terminal Browser does not support $platform $(uname -m)." >&2
            exit 1
            ;;
    esac

    if [[ "$platform" == Darwin ]]; then
        engine="$REAL_HOME/.local/share/terminal-browser/app/electron/terminal-browser.app/Contents/MacOS/terminal-browser"
    fi

    if [[ "$platform" == Linux ]]; then
        if declare -F omarchy_pkg_add >/dev/null; then
            omarchy_pkg_add nss gtk3 alsa-lib mesa
        else
            if declare -F wait_for_apt >/dev/null; then
                wait_for_apt
            fi
            if declare -F apt_do >/dev/null; then
                apt_do update
            else
                sys_do env DEBIAN_FRONTEND=noninteractive apt-get update
            fi

            # Debian 12 uses the original names; newer Debian/Ubuntu use t64.
            for package in "${packages[@]}"; do
                if apt-cache show "${package}t64" >/dev/null 2>&1; then
                    resolved_packages+=("${package}t64")
                else
                    resolved_packages+=("$package")
                fi
            done
            if declare -F apt_do >/dev/null; then
                apt_do install -y --no-remove "${resolved_packages[@]}"
            else
                sys_do env DEBIAN_FRONTEND=noninteractive apt-get install \
                    -y --no-remove "${resolved_packages[@]}"
            fi
        fi
    fi

    # Reuse a working installation: the upstream installer stops running browsers.
    if [[ -x "$binary" && -x "$engine" ]] && user_do "$binary" --version >/dev/null 2>&1; then
        echo "Terminal Browser is already installed; preserving the current version."
    else
        user_do mkdir -p "$REAL_HOME/.setupvibe/tmp"
        temporary_dir=$(user_do mktemp -d "$REAL_HOME/.setupvibe/tmp/terminal-browser.XXXXXX")
        trap 'user_do rm -rf -- "$temporary_dir"' EXIT
        safe_download https://terminal-browser.sh/install "$temporary_dir/install.sh" 500
        bash -n "$temporary_dir/install.sh"
        user_do env PATH="$REAL_HOME/.local/bin:$PATH" \
            XDG_DATA_HOME="$REAL_HOME/.local/share" XDG_BIN_HOME="$REAL_HOME/.local/bin" \
            TERMINAL_BROWSER_SKIP_SETUP=1 bash "$temporary_dir/install.sh"
    fi

    user_do "$binary" --version
    user_do test -x "$engine"
    if [[ "$platform" == Linux ]]; then
        missing_libraries=$(user_do ldd "$engine" | awk '/not found/ {print $1}')
        if [[ -n "$missing_libraries" ]]; then
            printf 'Error: Terminal Browser is missing system libraries:\n%s\n' "$missing_libraries" >&2
            exit 1
        fi
    fi
    # Load the bundled runtime without opening a UI or requiring a display/TTY.
    user_do env ELECTRON_RUN_AS_NODE=1 "$engine" -e 'process.exit(0)'
    echo "Terminal Browser validated. Open a page with: terminal-browser open https://example.com"
)
