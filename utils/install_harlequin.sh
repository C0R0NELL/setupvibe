#!/bin/bash

# Sourced by Unix installers; keep the system Python and user profiles intact.
setupvibe_install_harlequin() (
    set -euo pipefail

    local validation_helper=$1
    local uv_bin
    local tool_root
    local temporary_dir
    local tool_bin="$REAL_HOME/.local/bin"

    uv_bin=$(user_do env PATH="$tool_bin:$PATH" sh -c 'command -v uv' || true)
    if [[ -z "$uv_bin" ]] && declare -F omarchy_pkg_add >/dev/null; then
        omarchy_pkg_add uv
        uv_bin=$(user_do env PATH="$tool_bin:$PATH" sh -c 'command -v uv')
    fi
    if [[ -z "$uv_bin" ]]; then
        user_do mkdir -p "$REAL_HOME/.setupvibe/tmp"
        temporary_dir=$(user_do mktemp -d "$REAL_HOME/.setupvibe/tmp/harlequin.XXXXXX")
        trap 'user_do rm -rf -- "$temporary_dir"' EXIT
        safe_download https://astral.sh/uv/install.sh "$temporary_dir/uv-install.sh" 500
        user_do env UV_INSTALL_DIR="$tool_bin" UV_NO_MODIFY_PATH=1 \
            sh "$temporary_dir/uv-install.sh"
        uv_bin="$tool_bin/uv"
    fi

    user_do "$uv_bin" --version
    user_do env PATH="$tool_bin:$PATH" UV_TOOL_BIN_DIR="$tool_bin" \
        "$uv_bin" tool install --python 3.14 --no-cache 'harlequin[postgres,mysql]'
    tool_root=$(user_do "$uv_bin" tool dir)
    [[ "$tool_root" == /* ]] || {
        echo "Error: uv did not return an absolute tool directory." >&2
        exit 1
    }
    user_do "$tool_root/harlequin/bin/python" "$validation_helper"
    user_do "$tool_bin/harlequin" --version
    user_do "$tool_bin/harlequin" --help >/dev/null
    user_do "$tool_bin/hsql" --help >/dev/null
    echo "Harlequin validated with Python 3.14, PostgreSQL and MySQL adapters."
)
