#!/usr/bin/env python3
"""
Save and merge settings into ~/.config/dynamic-island/userconfig.json atomically.
Accepts JSON patch either as argv[1] or via stdin.
"""
import sys
import json
import os

CONFIG_PATH = os.path.expanduser("~/.config/dynamic-island/userconfig.json")
LEGACY_CONFIG_PATH = os.path.expanduser("~/.config/tide-island/userconfig.json")

def main():
    if len(sys.argv) > 1 and sys.argv[1].strip():
        raw = sys.argv[1]
    else:
        raw = sys.stdin.read()

    if not raw or not raw.strip():
        print("EMPTY")
        return

    try:
        patch = json.loads(raw)
    except Exception as e:
        sys.stderr.write(f"Invalid JSON: {e}\n")
        sys.exit(1)

    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    existing = {}
    
    # Read from primary or fallback legacy
    target_read = CONFIG_PATH if os.path.exists(CONFIG_PATH) else LEGACY_CONFIG_PATH
    if os.path.exists(target_read):
        try:
            with open(target_read, "r", encoding="utf-8") as f:
                existing = json.load(f)
        except Exception as e:
            sys.stderr.write(f"Warning: failed reading existing config ({e}), starting fresh.\n")
            existing = {}

    existing.update(patch)

    try:
        with open(CONFIG_PATH, "w", encoding="utf-8") as f:
            json.dump(existing, f, indent=4, ensure_ascii=False)
            f.write("\n")
        
        # Also sync legacy path if it's a separate real directory
        if os.path.exists(os.path.dirname(LEGACY_CONFIG_PATH)) and not os.path.samefile(os.path.dirname(CONFIG_PATH), os.path.dirname(LEGACY_CONFIG_PATH)):
            try:
                with open(LEGACY_CONFIG_PATH, "w", encoding="utf-8") as f:
                    json.dump(existing, f, indent=4, ensure_ascii=False)
                    f.write("\n")
            except Exception:
                pass
        print("OK")
    except Exception as e:
        sys.stderr.write(f"Error writing config: {e}\n")
        sys.exit(1)

if __name__ == "__main__":
    main()
