#!/usr/bin/env python3
"""
Scan system font files from the PC using fontconfig (fc-list).
Discovers all installed font files across /usr/share/fonts, ~/.local/share/fonts, etc.
Extracts all unique font families and classifies fonts suitable for icons & glyphs.
Caches results to ~/.cache/dynamic-island/fonts_cache.json for instant shell access.
"""

import subprocess
import os
import sys
import json

def scan_fonts():
    cache_dir = os.path.expanduser("~/.cache/dynamic-island")
    os.makedirs(cache_dir, exist_ok=True)
    cache_file = os.path.join(cache_dir, "fonts_cache.json")

    cmd = ["fc-list", ":", "family", "file"]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=5.0)
    except Exception as e:
        sys.stderr.write(f"[FontScanner] Error running fc-list: {e}\n")
        return {"all": [], "icons": [], "total_files": 0, "total_families": 0}

    all_fonts = set()
    icon_fonts = set()
    files_set = set()

    icon_patterns = [
        "nerd font", "nerdfont", "fontawesome", "font awesome", "font-awesome",
        "material symbol", "material icon", "material design",
        "symbols nerd font", "feather", "phosphor", "remix", "tabler",
        "devicon", "octicon", "weather icon", "ionicons", "lineicons"
    ]

    for line in res.stdout.strip().split("\n"):
        if not line or ":" not in line:
            continue
        parts = line.split(":")
        fpath = parts[0].strip()
        files_set.add(fpath)
        fams = ":".join(parts[1:]).strip()
        for fam in fams.split(","):
            f = fam.strip()
            if not f or f.startswith("."):
                continue
            all_fonts.add(f)

            low_f = f.lower()
            low_path = os.path.basename(fpath).lower()
            combo = low_f + " " + low_path

            if any(p in combo for p in icon_patterns):
                if "semicondensed" in low_f and not any(p in low_f for p in ["nerd", "awesome", "material", "symbol"]):
                    continue
                icon_fonts.add(f)

    data = {
        "all": sorted(list(all_fonts), key=lambda x: x.lower()),
        "icons": sorted(list(icon_fonts), key=lambda x: x.lower()),
        "total_files": len(files_set),
        "total_families": len(all_fonts)
    }

    try:
        with open(cache_file, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False)
    except Exception as e:
        sys.stderr.write(f"[FontScanner] Error writing cache: {e}\n")

    return data

if __name__ == "__main__":
    data = scan_fonts()
    if "--print" in sys.argv or "--json" in sys.argv:
        print(json.dumps(data))
    else:
        print(f"Scanned {data['total_files']} font files, {data['total_families']} font families, {len(data['icons'])} icon families.")
