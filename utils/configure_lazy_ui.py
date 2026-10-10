#!/usr/bin/env python3
"""Apply SetupVibe's Lazy UI defaults using only the Python standard library."""

import os
from pathlib import Path
import re
import shutil
import subprocess
import sys


OPTIONS = {
    "lazygit": {"nerdFontsVersion": '"3"', "showFileIcons": "true"},
    "lazydocker": {
        "containerStatusHealthStyle": '"icon"',
        "border": '"rounded"',
        "expandFocusedSidePanel": "true",
    },
}


def config_path(app, executable):
    if app == "lazygit":
        if os.environ.get("LG_CONFIG_FILE"):
            print("SKIPPED: lazygit uses custom LG_CONFIG_FILE files")
            return None
        directory = subprocess.check_output(
            [executable, "--print-config-dir"], text=True, encoding="utf-8", timeout=15
        ).strip()
        if not directory:
            raise ValueError("lazygit returned an empty configuration directory")
        return Path(directory) / "config.yml"

    # Match lazydocker's CONFIG_DIR override and OpenPeeDeeP/xdg resolver.
    if os.environ.get("CONFIG_DIR"):
        return Path(os.environ["CONFIG_DIR"]) / "config.yml"
    if os.environ.get("XDG_CONFIG_HOME"):
        base = Path(os.environ["XDG_CONFIG_HOME"])
    elif sys.platform == "win32":
        base = Path(os.environ["APPDATA"])
    elif sys.platform == "darwin":
        base = Path.home() / "Library" / "Application Support"
    else:
        base = Path.home() / ".config"
    legacy = base / "jesseduffield" / app
    return (legacy if legacy.exists() else base / app) / "config.yml"


def merge_gui(old, options):
    """Edit a conventional block mapping; leave unfamiliar YAML untouched."""
    newline = "\r\n" if "\r\n" in old else "\n"
    lines = old.splitlines(keepends=True)
    top_level = [line for line in lines if line.strip() and not line[0].isspace()
                 and not line.startswith("#")]
    if not top_level and any(line.strip() and not line.lstrip().startswith("#") for line in lines):
        return None
    if any(not re.match(r"^(?:[\w-]+|'[^']+'|\"[^\"]+\")\s*:", line)
           for line in top_level):
        return None
    matches = [i for i, line in enumerate(lines)
               if re.match(r"^gui:\s*(?:#.*)?$", line.rstrip("\r\n"))]
    gui_keys = [line for line in top_level
                if re.match(r"^(?:gui|'gui'|\"gui\")\s*:", line)]
    if len(gui_keys) != len(matches) or len(matches) > 1:
        return None

    if matches:
        start = matches[0]
        end = next((i for i in range(start + 1, len(lines))
                    if lines[i] in top_level), len(lines))
        body = lines[start + 1:end]
        content = [line for line in body if line.strip()
                   and not line.lstrip().startswith("#")]
        if any("\t" in line[:len(line) - len(line.lstrip())] for line in content):
            return None
        indent = min((len(line) - len(line.lstrip(" "))
                      for line in content), default=2)
        prefix = " " * indent
        if any(not re.match(r"^" + prefix + r"(?:[\w-]+|'[^']+'|\"[^\"]+\"|<<)\s*:", line)
               for line in content if len(line) - len(line.lstrip(" ")) == indent):
            return None
        pattern = re.compile(r"^" + prefix + r"(" + "|".join(options) + r")\s*:")
        for line in content:
            # Settings must be flat scalars, not nested or multiline values.
            if pattern.match(line):
                value = line.split(":", 1)[1].strip()
                if not value or value.startswith(("#", "|", ">", "{", "[", "&", "*")):
                    return None
            elif re.match(r"^" + prefix + r"['\"](?:" + "|".join(options) + r")[ '\"]*:", line):
                return None
        replacement = [f"{prefix}{key}: {value}{newline}" for key, value in options.items()]
        lines = lines[:start + 1] + replacement + [line for line in body
                                                  if not pattern.match(line)] + lines[end:]
    else:
        if lines and lines[-1].strip():
            lines.append(newline)
        lines += [f"gui:{newline}"] + [f"  {key}: {value}{newline}"
                                       for key, value in options.items()]
    # Existing files may omit the final newline.
    return "".join(line if line.endswith("\n") else line + newline for line in lines)


def configure(path, options):
    original = path.read_bytes() if path.exists() else b""
    has_bom = original.startswith(b"\xef\xbb\xbf")
    new = merge_gui(original.decode("utf-8-sig"), options)
    if new is None:
        print(f"SKIPPED: {path} (unconventional YAML structure)")
        return
    encoded = (b"\xef\xbb\xbf" if has_bom else b"") + new.encode("utf-8")
    if encoded == original:
        print(f"ALREADY CONFIGURED: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    backup = path.with_name("config.yml.bak")
    if path.exists() and not backup.exists():
        shutil.copy2(path, backup)
    path.write_bytes(encoded)
    print(f"CONFIGURED: {path}")


def main():
    failed = False
    for app, options in OPTIONS.items():
        executable = shutil.which(app)
        if not executable:
            print(f"SKIPPED: {app} is not installed")
            continue
        try:
            path = config_path(app, executable)
            if path is not None:
                configure(path, options)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"ERROR: {app}: {error}", file=sys.stderr)
            failed = True
    return int(failed)


if __name__ == "__main__":
    sys.exit(main())
