#!/bin/bash

# Sourced by Unix installers; the upstream installer verifies release SHA-256.
setupvibe_install_redis_tui() (
    set -euo pipefail

    local binary="$REAL_HOME/.local/bin/redis-tui"
    local temporary_dir

    case "$(uname -s)-$(uname -m)" in
        Darwin-arm64|Darwin-x86_64|Linux-x86_64|Linux-amd64|Linux-aarch64|Linux-arm64) ;;
        *)
            echo "Error: Redis TUI does not support $(uname -s)/$(uname -m)." >&2
            exit 1
            ;;
    esac

    if [[ -x "$binary" ]] && user_do "$binary" --version >/dev/null 2>&1 \
        && user_do "$binary" --help >/dev/null 2>&1; then
        echo "Redis TUI is already installed; preserving the current version."
    else
        user_do mkdir -p "$REAL_HOME/.setupvibe/tmp"
        temporary_dir=$(user_do mktemp -d "$REAL_HOME/.setupvibe/tmp/redis-tui.XXXXXX")
        trap 'user_do rm -rf -- "$temporary_dir"' EXIT
        safe_download https://raw.githubusercontent.com/davidbudnick/redis-tui/main/install.sh \
            "$temporary_dir/install.sh" 500
        bash -n "$temporary_dir/install.sh"
        user_do env INSTALL_DIR="$temporary_dir/bin" TMPDIR="$temporary_dir" \
            PATH="$REAL_HOME/.local/bin:$PATH" bash "$temporary_dir/install.sh"
        user_do "$temporary_dir/bin/redis-tui" --version
        user_do "$temporary_dir/bin/redis-tui" --help >/dev/null 2>&1
        user_do mkdir -p "$(dirname -- "$binary")"
        user_do install -m 0755 "$temporary_dir/bin/redis-tui" "$binary"
    fi

    user_do "$binary" --version
    user_do "$binary" --help >/dev/null 2>&1
    echo "Redis TUI validated; saved connections and shell profiles were preserved."
)
