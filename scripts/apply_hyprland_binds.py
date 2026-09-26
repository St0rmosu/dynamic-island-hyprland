#!/usr/bin/env python3
"""
apply_hyprland_binds.py
Updates ~/.config/hypr/moduli/binds.lua and ~/.config/dynamic-island/hyprland-shortcuts.conf
with custom shortcuts defined in Dynamic Island, then reloads Hyprland.
"""

import sys
import os
import json
import re
import subprocess

HOME = os.environ.get("HOME", "/home/lollo")
BINDS_LUA = os.path.join(HOME, ".config/hypr/moduli/binds.lua")
SHORTCUTS_CONF_DYNAMIC = os.path.join(HOME, ".config/dynamic-island/hyprland-shortcuts.conf")
SHORTCUTS_CONF_TIDE = os.path.join(HOME, ".config/tide-island/hyprland-shortcuts.conf")
CONFIG_JSON = os.path.join(HOME, ".config/dynamic-island/config.json")

# Map of action to human-readable names and defaults
ACTION_MAP = {
    "overview": "overview",
    "power": "power",
    "notifications": "notifications",
    "master-or-wallpaper": "master-or-wallpaper",
    "apps": "apps",
    "files": "files",
    "clipboard": "clipboard"
}

def format_lua_bind(keys, action):
    has_super = "SUPER" in keys
    other_keys = [k for k in keys if k != "SUPER"]
    mapped_other = ["space" if k == "Spazio" else k for k in other_keys]
    
    if has_super:
        if mapped_other:
            key_expr = f'mainMod .. " + {" + ".join(mapped_other)}"'
        else:
            key_expr = 'mainMod'
    else:
        mapped_all = ["space" if k == "Spazio" else k for k in keys]
        key_expr = f'"{ " + ".join(mapped_all) }"'
        
    return f'hl.bind({key_expr}, hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh {action}"))'

def format_conf_bind(keys, action):
    # Format for hyprland.conf style: bind = SUPER ALT, space, exec, ...
    mods = [k for k in keys if k in ("SUPER", "CTRL", "ALT", "SHIFT")]
    non_mods = [k for k in keys if k not in ("SUPER", "CTRL", "ALT", "SHIFT")]
    
    mod_str = " ".join(mods)
    key_str = non_mods[0] if non_mods else ""
    if key_str == "Spazio":
        key_str = "space"
    elif key_str == "Tab":
        key_str = "TAB"
        
    return f'bind = {mod_str}, {key_str}, exec, $HOME/.scripts/shell-dispatcher.sh {action}'

def main():
    shortcuts = None
    
    # Try reading from CLI argument first
    if len(sys.argv) > 1 and sys.argv[1].strip():
        try:
            shortcuts = json.loads(sys.argv[1])
        except Exception as e:
            pass
            
    # Fallback: read from config.json
    if not shortcuts and os.path.exists(CONFIG_JSON):
        try:
            with open(CONFIG_JSON, "r") as f:
                cfg = json.load(f)
                shortcuts = cfg.get("customShortcuts", [])
        except Exception:
            pass
            
    if not shortcuts or not isinstance(shortcuts, list):
        print(json.dumps({"status": "error", "message": "No valid shortcuts provided"}))
        return 1

    # 1. Update ~/.config/hypr/moduli/binds.lua
    updated_lua_count = 0
    if os.path.exists(BINDS_LUA):
        try:
            with open(BINDS_LUA, "r") as f:
                lua_content = f.read()

            for item in shortcuts:
                act = item.get("action")
                keys = item.get("keys", [])
                if not act or not keys:
                    continue

                new_line = format_lua_bind(keys, act)
                
                # Regex matches hl.bind(..., hl.dsp.exec_cmd("$HOME/.scripts/shell-dispatcher.sh <act>"))
                pattern = re.compile(
                    r'hl\.bind\([^,]+,\s*hl\.dsp\.exec_cmd\([\'"]\$HOME/\.scripts/shell-dispatcher\.sh\s+' + re.escape(act) + r'[\'"]\)\)',
                    re.MULTILINE
                )
                
                if pattern.search(lua_content):
                    lua_content, count = pattern.subn(new_line, lua_content, count=1)
                    if count > 0:
                        updated_lua_count += 1

            with open(BINDS_LUA, "w") as f:
                f.write(lua_content)
        except Exception as e:
            print(json.dumps({"status": "error", "message": f"Failed updating binds.lua: {e}"}))
            return 1

    # 2. Reload Hyprland
    try:
        subprocess.run(["hyprctl", "reload"], check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    print(json.dumps({
        "status": "ok",
        "updated_binds": updated_lua_count,
        "message": f"Applicate {updated_lua_count} scorciatoie a Hyprland!"
    }))
    return 0

if __name__ == "__main__":
    sys.exit(main())
