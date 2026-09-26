#!/usr/bin/env python3
import sys
import os
import glob
import re
import urllib.request
import time

def resolve_avatar(caller_name):
    if not caller_name:
        return ""

    caller_clean = caller_name.strip()
    caller_lower = caller_clean.lower()

    # 1. Check custom contacts folder in dynamic-island/avatars
    custom_dir = os.path.expanduser("~/.config/quickshell/dynamic-island/avatars")
    for name_candidate in (caller_clean, caller_lower):
        for ext in (".png", ".jpg", ".jpeg", ".webp"):
            candidate_path = os.path.join(custom_dir, name_candidate + ext)
            if os.path.isfile(candidate_path):
                return f"file://{candidate_path}"

    # 2. Check cached avatars in ~/.cache/dynamic-island/avatars
    cache_dir = os.path.expanduser("~/.cache/dynamic-island/avatars")
    os.makedirs(cache_dir, exist_ok=True)
    cached_file = os.path.join(cache_dir, f"{caller_lower}.png")
    if os.path.isfile(cached_file) and os.path.getsize(cached_file) > 100:
        return f"file://{cached_file}"

    # 3. Check /tmp/dynamic_discord_call_avatar.png if recent (< 30s)
    tmp_avatar = "/tmp/dynamic_discord_call_avatar.png"
    if os.path.isfile(tmp_avatar) and (time.time() - os.path.getmtime(tmp_avatar) < 30):
        return f"file://{tmp_avatar}"

    # 4. Search Discord LevelDB for the user profile
    discord_ldb_dir = os.path.expanduser("~/.config/discord/Local Storage/leveldb")
    found_id = None
    found_avatar = None

    files = glob.glob(os.path.join(discord_ldb_dir, "*.ldb")) + glob.glob(os.path.join(discord_ldb_dir, "*.log"))
    for f in files:
        try:
            with open(f, "rb") as fp:
                content = fp.read()
                # Find all user objects
                for m in re.finditer(rb'\{[^{}]*?\"id\":\"(\d{17,19})\"[^{}]*?\}', content):
                    u_json = m.group(0)
                    if b"avatar" in u_json and (b"username" in u_json or b"global_name" in u_json):
                        # Decode and check if caller name matches
                        u_str = u_json.decode("utf-8", errors="ignore").lower()
                        if caller_lower in u_str:
                            id_m = re.search(r'\"id\":\"(\d{17,19})\"', u_str)
                            av_m = re.search(r'\"avatar\":\"([a-f0-9_]+)\"', u_str)
                            if id_m and av_m:
                                found_id = id_m.group(1)
                                found_avatar = av_m.group(1)
                                break
        except Exception:
            pass
        if found_id and found_avatar:
            break

    if found_id and found_avatar:
        # Check Chromium disk cache first
        discord_cache_dir = os.path.expanduser("~/.config/discord/Cache/Cache_Data")
        url_sub = f"{found_id}/{found_avatar}".encode()
        for cf in glob.glob(os.path.join(discord_cache_dir, "*_0")):
            try:
                with open(cf, "rb") as cfp:
                    chead = cfp.read(300)
                    if url_sub in chead:
                        cdata = cfp.read()
                        r_idx = cdata.find(b"RIFF")
                        if r_idx != -1:
                            with open(cached_file, "wb") as out_f:
                                out_f.write(cdata[r_idx:])
                            return f"file://{cached_file}"
            except Exception:
                pass

        # Download from CDN
        cdn_url = f"https://cdn.discordapp.com/avatars/{found_id}/{found_avatar}.png?size=128"
        try:
            req = urllib.request.Request(cdn_url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=3) as resp, open(cached_file, "wb") as out_f:
                out_f.write(resp.read())
            if os.path.isfile(cached_file) and os.path.getsize(cached_file) > 100:
                return f"file://{cached_file}"
        except Exception:
            pass

    return ""

if __name__ == "__main__":
    name = sys.argv[1] if len(sys.argv) > 1 else ""
    res = resolve_avatar(name)
    if res:
        print(res)
