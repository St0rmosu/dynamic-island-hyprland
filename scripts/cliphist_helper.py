#!/usr/bin/env python3
"""
cliphist_helper.py - Clipboard history backend helper for Quickshell Dynamic Island.

Provides fast JSON output with image thumbnail caching, item decoding, copying,
deleting, and clearing.
"""

import sys
import os
import argparse
import subprocess
import json
import re
import time
from datetime import datetime, timedelta
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor

CACHE_DIR = Path("/tmp/cliphist_thumbs")
FAVICON_DIR = Path("/tmp/cliphist-favicons")
TIMESTAMPS_FILE = CACHE_DIR / "timestamps.json"

FRIENDLY_DOMAINS = {
    "github.com": "GitHub",
    "gist.github.com": "GitHub Gist",
    "gitlab.com": "GitLab",
    "youtube.com": "YouTube",
    "youtu.be": "YouTube",
    "music.youtube.com": "YouTube Music",
    "reddit.com": "Reddit",
    "old.reddit.com": "Reddit",
    "google.com": "Google",
    "x.com": "X (Twitter)",
    "twitter.com": "Twitter",
    "instagram.com": "Instagram",
    "facebook.com": "Facebook",
    "wikipedia.org": "Wikipedia",
    "en.wikipedia.org": "Wikipedia",
    "it.wikipedia.org": "Wikipedia",
    "stackoverflow.com": "Stack Overflow",
    "stackexchange.com": "Stack Exchange",
    "twitch.tv": "Twitch",
    "discord.com": "Discord",
    "discord.gg": "Discord",
    "spotify.com": "Spotify",
    "open.spotify.com": "Spotify",
    "amazon.it": "Amazon",
    "amazon.com": "Amazon",
    "netflix.com": "Netflix",
    "archlinux.org": "Arch Linux",
    "wiki.archlinux.org": "Arch Wiki",
    "aur.archlinux.org": "AUR",
    "hyprland.org": "Hyprland",
    "wiki.hyprland.org": "Hyprland Wiki",
    "telegram.org": "Telegram",
    "t.me": "Telegram",
    "whatsapp.com": "WhatsApp",
    "web.whatsapp.com": "WhatsApp Web",
    "duckduckgo.com": "DuckDuckGo",
    "medium.com": "Medium",
    "dev.to": "DEV Community",
    "npm.im": "npm",
    "npmjs.com": "npm",
    "pypi.org": "PyPI",
    "crates.io": "crates.io",
}


def ensure_dirs():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    FAVICON_DIR.mkdir(parents=True, exist_ok=True)


def fetch_favicon(domain: str) -> str:
    """Downloads domain favicon from Google Favicons API with short timeout."""
    if not domain:
        return ""
    clean_domain = domain.split(":")[0]
    fav_file = FAVICON_DIR / f"{clean_domain}.png"
    if fav_file.exists() and fav_file.stat().st_size > 0:
        return str(fav_file)
    fav_url = f"https://www.google.com/s2/favicons?domain={clean_domain}&sz=64"
    try:
        import urllib.request
        req = urllib.request.Request(fav_url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=1.2) as resp:
            data = resp.read()
            if len(data) > 0:
                with open(fav_file, "wb") as f:
                    f.write(data)
                return str(fav_file)
    except Exception:
        pass
    return ""


def extract_url_info(text: str):
    """Detects if text contains or is a URL, extracting domain, source name, clean title, and favicon path."""
    t = text.strip()
    m = re.search(r'(https?://[^\s]+|www\.[^\s]+)', t)
    if not m:
        return False, "", "", "", "", ""
    
    url = m.group(1)
    full_url = "https://" + url if url.startswith("www.") else url
    try:
        from urllib.parse import urlparse
        parsed = urlparse(full_url)
        netloc = (parsed.netloc or "").lower()
        if not netloc:
            return False, "", "", "", "", ""
        clean_domain = netloc.split(":")[0]
        lookup_domain = clean_domain[4:] if clean_domain.startswith("www.") else clean_domain

        source_name = FRIENDLY_DOMAINS.get(lookup_domain) or FRIENDLY_DOMAINS.get(clean_domain)
        if not source_name:
            parts = lookup_domain.split(".")
            if len(parts) >= 2:
                source_name = parts[0].capitalize() + "." + ".".join(parts[1:])
            else:
                source_name = lookup_domain

        fav_path = str(FAVICON_DIR / f"{clean_domain}.png")
        path = parsed.path.strip("/")
        if path:
            title = f"{source_name} • /{path[:28]}"
        else:
            title = f"{source_name} Link"

        preview = full_url[:120]
        return True, clean_domain, source_name, fav_path, title, preview
    except Exception:
        return False, "", "", "", "", ""


def load_timestamps() -> dict:
    if TIMESTAMPS_FILE.exists():
        try:
            with open(TIMESTAMPS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}


def save_timestamps(timestamps: dict):
    try:
        with open(TIMESTAMPS_FILE, "w", encoding="utf-8") as f:
            json.dump(timestamps, f)
    except Exception:
        pass


def format_timestamp(ts: float) -> str:
    dt = datetime.fromtimestamp(ts)
    now = datetime.now()
    diff = now - dt

    if diff.days == 0:
        # Today: format like "9:10 AM"
        return dt.strftime("%-I:%M %p")
    elif diff.days == 1:
        return "Yesterday"
    elif diff.days < 7:
        return dt.strftime("%a %-I:%M %p")
    else:
        return dt.strftime("%b %-d")


def decode_image_thumb(cid: str, thumb_path: Path) -> bool:
    """Decodes binary image from cliphist and saves to thumb_path."""
    try:
        if thumb_path.exists() and thumb_path.stat().st_size > 0:
            return True
        res = subprocess.run(
            ["cliphist", "decode", str(cid)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=2.0
        )
        if res.returncode == 0 and len(res.stdout) > 0:
            temp_path = thumb_path.with_suffix(".tmp")
            with open(temp_path, "wb") as f:
                f.write(res.stdout)
            temp_path.replace(thumb_path)
            return True
    except Exception:
        pass
    return False


def decode_text_content(cid: str) -> str:
    """Decodes text from cliphist."""
    try:
        res = subprocess.run(
            ["cliphist", "decode", str(cid)],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=1.5
        )
        if res.returncode == 0:
            return res.stdout
    except Exception:
        pass
    return ""


def parse_title_and_preview(text: str):
    """Derives a clean title and body preview from text content."""
    text = text.strip()
    if not text:
        return "", ""

    # Check for URL
    if text.startswith("http://") or text.startswith("https://"):
        from urllib.parse import urlparse
        try:
            parsed = urlparse(text)
            domain = parsed.netloc or parsed.path.split("/")[0]
            path_part = parsed.path.strip("/")
            title = domain if not path_part else f"{domain}/{path_part[:24]}"
            return title, text
        except Exception:
            return text[:40], text

    lines = [line.strip() for line in text.splitlines() if line.strip()]
    if not lines:
        return text[:40], text[:120]

    first_line = lines[0]
    if len(lines) > 1:
        title = first_line[:55]
        preview = " ".join(lines[1:])[:140]
        return title, preview

    # Single line
    if len(first_line) > 50:
        # Split on sentence, colon, or comma if available
        split_match = re.split(r"(?<=[.:\-])\s+", first_line, maxsplit=1)
        if len(split_match) == 2 and 5 <= len(split_match[0]) <= 45:
            return split_match[0], split_match[1][:120]
        return first_line[:45] + "...", first_line
    else:
        return first_line, ""


def process_entry(raw_line: str, timestamps: dict, base_now: float, fallback_offset: int):
    parts = raw_line.split("\t", 1)
    if len(parts) < 2:
        return None

    cid = parts[0].strip()
    raw_content = parts[1].strip()

    # Determine or retrieve timestamp
    if cid in timestamps:
        ts = timestamps[cid]
    else:
        # Stagger initial timestamps naturally if unknown
        ts = base_now - (fallback_offset * 120)
        timestamps[cid] = ts

    time_str = format_timestamp(ts)

    # Check if binary image
    is_image = raw_content.startswith("[[ binary data")
    if is_image:
        thumb_path = CACHE_DIR / f"{cid}.png"
        decode_image_thumb(cid, thumb_path)

        # Parse info like "[[ binary data 59 KiB png 213x339 ]]"
        img_match = re.search(r"\[\[ binary data ([\d.]+\s*\w+) (\w+) (\d+x\d+) \]\]", raw_content)
        if img_match:
            size_str = img_match.group(1)
            fmt_str = img_match.group(2).upper()
            dims = img_match.group(3).replace("x", "×")

            # Label like "Screenshot" or "Image (1920×1080)"
            if "1920×1080" in dims or "2560×1440" in dims or "3840×2160" in dims:
                title = f"Screenshot ({dims})"
            else:
                title = f"{fmt_str} Image ({dims})"
            preview = f"{fmt_str} • {size_str} • {dims}"
        else:
            title = "Clipboard Image"
            preview = "Image Data"

        return {
            "id": str(cid),
            "type": "image",
            "is_url": False,
            "domain": "",
            "source_name": "",
            "favicon": "",
            "title": title,
            "content": raw_content,
            "time": time_str,
            "thumb": str(thumb_path),
            "preview": preview
        }
    else:
        # Text entry
        full_text = decode_text_content(cid)
        if not full_text:
            full_text = raw_content

        is_url, domain, source_name, fav_path, url_title, url_preview = extract_url_info(full_text)
        if is_url:
            return {
                "id": str(cid),
                "type": "link",
                "is_url": True,
                "domain": domain,
                "source_name": source_name,
                "favicon": fav_path if Path(fav_path).exists() else "",
                "title": url_title,
                "content": full_text[:1000],
                "time": time_str,
                "thumb": "",
                "preview": url_preview
            }

        title, preview = parse_title_and_preview(full_text)
        if not title:
            title = full_text[:40]
        if not preview:
            preview = full_text[:120]

        return {
            "id": str(cid),
            "type": "text",
            "is_url": False,
            "domain": "",
            "source_name": "",
            "favicon": "",
            "title": title,
            "content": full_text[:1000],  # Keep json compact
            "time": time_str,
            "thumb": "",
            "preview": preview
        }


def list_entries(limit: int = 50, query: str = ""):
    ensure_dirs()
    timestamps = load_timestamps()
    base_now = time.time()

    try:
        res = subprocess.run(
            ["cliphist", "list"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=2.0
        )
        lines = [l for l in res.stdout.splitlines() if l.strip()]
    except Exception as e:
        print(json.dumps([]))
        return

    if query:
        q_lower = query.lower()
        lines = [l for l in lines if q_lower in l.lower()]

    lines = lines[:limit]

    # Process items in parallel
    results = []
    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = [
            executor.submit(process_entry, line, timestamps, base_now, idx)
            for idx, line in enumerate(lines)
        ]
        for f in futures:
            item = f.result()
            if item:
                results.append(item)

    # Fetch any missing favicons in parallel
    domains_to_fetch = list(set(
        item["domain"] for item in results
        if item.get("is_url") and item.get("domain") and not Path(FAVICON_DIR / f"{item['domain']}.png").exists()
    ))
    if domains_to_fetch:
        with ThreadPoolExecutor(max_workers=6) as executor:
            list(executor.map(fetch_favicon, domains_to_fetch))
        for item in results:
            if item.get("is_url") and item.get("domain"):
                fpath = FAVICON_DIR / f"{item['domain']}.png"
                if fpath.exists() and fpath.stat().st_size > 0:
                    item["favicon"] = str(fpath)

    # Save updated timestamps
    save_timestamps(timestamps)

    json_str = json.dumps(results, ensure_ascii=False)
    for cpath in [CACHE_DIR / "cliphist_cache.json", Path("/tmp/cliphist_cache.json")]:
        try:
            with open(cpath, "w", encoding="utf-8") as f:
                f.write(json_str)
        except Exception:
            pass

    print(json_str)


def copy_entry(cid: str):
    try:
        p1 = subprocess.Popen(["cliphist", "decode", str(cid)], stdout=subprocess.PIPE)
        p2 = subprocess.Popen(["wl-copy"], stdin=p1.stdout)
        p1.stdout.close()
        p2.communicate()
        sys.exit(p2.returncode)
    except Exception as e:
        sys.stderr.write(f"Copy error: {e}\n")
        sys.exit(1)


def delete_entry(cid: str):
    ensure_dirs()
    try:
        # Find exact line or use cid
        res = subprocess.run(
            ["cliphist", "list"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            encoding="utf-8",
            errors="replace"
        )
        target_line = None
        for line in res.stdout.splitlines():
            if line.startswith(f"{cid}\t") or line.strip() == str(cid):
                target_line = line
                break

        line_to_del = (target_line if target_line else str(cid)) + "\n"
        del_proc = subprocess.run(
            ["cliphist", "delete"],
            input=line_to_del.encode("utf-8"),
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )

        # Remove cached thumbnail if any
        thumb_file = CACHE_DIR / f"{cid}.png"
        if thumb_file.exists():
            thumb_file.unlink(missing_ok=True)

        sys.exit(del_proc.returncode)
    except Exception as e:
        sys.stderr.write(f"Delete error: {e}\n")
        sys.exit(1)


def clear_all():
    ensure_dirs()
    try:
        subprocess.run(["cliphist", "wipe"], check=True)
        # Clear cached thumbs
        for f in CACHE_DIR.glob("*.png"):
            f.unlink(missing_ok=True)
        if TIMESTAMPS_FILE.exists():
            TIMESTAMPS_FILE.unlink(missing_ok=True)
        sys.exit(0)
    except Exception as e:
        sys.stderr.write(f"Clear error: {e}\n")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Cliphist helper for Dynamic Island")
    parser.add_argument("--copy", metavar="ID", help="Copy cliphist entry to clipboard")
    parser.add_argument("--delete", metavar="ID", help="Delete cliphist entry")
    parser.add_argument("--clear", action="store_true", help="Clear all clipboard history")
    parser.add_argument("--list", action="store_true", help="List entries in JSON")
    parser.add_argument("--limit", type=int, default=50, help="Maximum number of items")
    parser.add_argument("--query", type=str, default="", help="Filter query")

    args = parser.parse_args()

    if args.copy:
        copy_entry(args.copy)
    elif args.delete:
        delete_entry(args.delete)
    elif args.clear:
        clear_all()
    else:
        list_entries(limit=args.limit, query=args.query)


if __name__ == "__main__":
    main()
