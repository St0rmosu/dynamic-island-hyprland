#!/usr/bin/env python3
"""
Scan system font files from the PC using fontconfig (fc-list) and filesystem search.
Discovers all installed font files across /usr/share/fonts, ~/.local/share/fonts, ~/.fonts, Flatpaks, etc.
Extracts all unique font families and classifies fonts suitable for icons & glyphs.
Caches results to ~/.cache/dynamic-island/fonts_cache.json for instant shell access.
100% portable for any user and system without hardcoded paths.
"""

import subprocess
import os
import sys
import json
import re

def scan_fonts():
    cache_dir = os.path.expanduser("~/.cache/dynamic-island")
    os.makedirs(cache_dir, exist_ok=True)
    cache_file = os.path.join(cache_dir, "fonts_cache.json")

    all_fonts = set()
    icon_fonts = set()
    files_set = set()

    icon_patterns = [
        "nerd font", "nerdfont", "fontawesome", "font awesome", "font-awesome",
        "material symbol", "material icon", "material design",
        "symbols nerd font", "feather", "phosphor", "remix", "tabler",
        "devicon", "octicon", "weather icon", "ionicons", "lineicons", "codicon"
    ]

    # 1. Prova prima con fc-list (veloce e copre tutte le directory registrate nel sistema)
    cmd = ["fc-list", ":", "family", "file"]
    fc_success = False
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=8.0)
        if res.returncode == 0 and res.stdout.strip():
            fc_success = True
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
    except Exception as e:
        sys.stderr.write(f"[FontScanner] fc-list not available or failed: {e}\n")

    # 2. Scansione dinamica delle directory standard del sistema e dell'utente (anche se fc-list manca)
    font_dirs = [
        os.path.expanduser("~/.local/share/fonts"),
        os.path.expanduser("~/.fonts"),
        "/usr/share/fonts",
        "/usr/local/share/fonts",
        "/var/lib/flatpak/exports/share/fonts",
        os.path.expanduser("~/.local/share/flatpak/exports/share/fonts"),
    ]
    font_exts = {".ttf", ".otf", ".woff", ".woff2", ".ttc"}

    for fdir in font_dirs:
        if not os.path.isdir(fdir):
            continue
        for root_dir, _, filenames in os.walk(fdir):
            for fname in filenames:
                ext = os.path.splitext(fname)[1].lower()
                if ext in font_exts:
                    full_p = os.path.join(root_dir, fname)
                    files_set.add(full_p)

                    # Se fc-list non è riuscito a estrarre i nomi, indovina il nome pulito dal file
                    if not fc_success:
                        base = os.path.splitext(fname)[0]
                        clean_name = re.sub(r'-(Regular|Bold|Italic|Medium|Light|SemiBold|ExtraBold|Black|Thin|VariableFont.*)$', '', base, flags=re.IGNORECASE).strip()
                        clean_name = clean_name.replace("-", " ").replace("_", " ")
                        if clean_name and not clean_name.startswith("."):
                            all_fonts.add(clean_name)
                            low = clean_name.lower()
                            if any(p in low for p in icon_patterns):
                                icon_fonts.add(clean_name)

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
