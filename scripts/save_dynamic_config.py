#!/usr/bin/env python3
"""
Atomic configuration store writer for Dynamic Island.
Writes to ~/.config/dynamic-island/config.json and syncs ~/.config/dynamic-island/userconfig.json.
"""
import sys
import json
import os

CONFIG_DIR = os.path.expanduser("~/.config/dynamic-island")
CONFIG_PATH = os.path.join(CONFIG_DIR, "config.json")
USERCONFIG_PATH = os.path.join(CONFIG_DIR, "userconfig.json")
LEGACY_DYNAMIC_PATH = os.path.expanduser("~/.config/dynamic-island/userconfig.json")

def atomic_write(filepath, content):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    tmp_path = filepath + ".tmp"
    with open(tmp_path, "w", encoding="utf-8") as f:
        f.write(content)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, filepath)

def main():
    if len(sys.argv) > 1 and sys.argv[1].strip():
        raw = sys.argv[1]
    else:
        raw = sys.stdin.read()

    if not raw or not raw.strip():
        print("EMPTY")
        return

    try:
        data = json.loads(raw)
    except Exception as e:
        sys.stderr.write(f"Invalid JSON: {e}\n")
        sys.exit(1)

    os.makedirs(CONFIG_DIR, exist_ok=True)
    existing = {}
    
    # Read existing config if present
    for candidate in [CONFIG_PATH, USERCONFIG_PATH, LEGACY_DYNAMIC_PATH]:
        if os.path.exists(candidate):
            try:
                with open(candidate, "r", encoding="utf-8") as f:
                    existing = json.load(f)
                    if existing:
                        break
            except Exception:
                pass

    existing.update(data)
    content = json.dumps(existing, indent=2, ensure_ascii=False) + "\n"

    try:
        atomic_write(CONFIG_PATH, content)
        atomic_write(USERCONFIG_PATH, content)
        # Also sync legacy config path if directory exists so external tools don't fail
        if os.path.isdir(os.path.dirname(LEGACY_DYNAMIC_PATH)):
            try:
                atomic_write(LEGACY_DYNAMIC_PATH, content)
            except Exception:
                pass
        print("OK")
    except Exception as e:
        sys.stderr.write(f"Error saving config: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
