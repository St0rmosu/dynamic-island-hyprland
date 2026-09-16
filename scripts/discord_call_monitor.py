#!/usr/bin/env python3
import subprocess
import re
import os
import sys
import time
import json
import threading

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)
from resolve_discord_avatar import resolve_avatar

ACTIVE_CALL = False
LAST_CALL_TIME = 0
STATE_FILE = "/tmp/tide_discord_call_ongoing"

def send_ipc(method, *args):
    ipc_path = os.path.expanduser("~/.config/quickshell/tide-island")
    cmd = ["quickshell", "ipc", "-p", ipc_path, "call", "island", method] + list(args)
    try:
        subprocess.run(cmd, timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

def close_call():
    global ACTIVE_CALL, LAST_CALL_TIME
    ACTIVE_CALL = False
    try:
        if os.path.exists(STATE_FILE):
            os.remove(STATE_FILE)
    except Exception:
        pass
    send_ipc("closeCall")

def get_discord_channel_or_contact():
    try:
        res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=1.5)
        clients = json.loads(res.stdout)
        for c in clients:
            cls = (c.get("class") or "").lower()
            if any(x in cls for x in ("discord", "vesktop", "armcord", "webcord")):
                title = c.get("title", "")
                if title and " - Discord" in title:
                    clean = title.split(" - Discord")[0].strip()
                    if clean and clean.lower() != "discord":
                        return clean
                elif title and title.lower() != "discord":
                    return title.strip()
    except Exception:
        pass
    return "Discord Call"

def is_discord_audio_active():
    try:
        res = subprocess.run(["pactl", "list", "source-outputs"], capture_output=True, text=True, timeout=1.5)
        out = res.stdout.lower()
        if "discord" in out or "webrtc" in out:
            return True
    except Exception:
        pass
    return False

def audio_monitor_loop():
    global ACTIVE_CALL, LAST_CALL_TIME
    prev_active = False
    while True:
        try:
            curr_active = is_discord_audio_active()
            if curr_active and not prev_active:
                # Discord voice stream started
                if not os.path.exists(STATE_FILE):
                    # Outgoing call or voice connection initiated in Discord
                    name = get_discord_channel_or_contact()
                    avatar = resolve_avatar(name) or ""
                    ACTIVE_CALL = True
                    LAST_CALL_TIME = time.time()
                    try:
                        with open(STATE_FILE, "w") as f:
                            f.write(str(time.time()))
                    except Exception:
                        pass
                    send_ipc("incomingCall", name, "In chiamata...", avatar)
                    time.sleep(0.08)
                    send_ipc("callAccepted")
                else:
                    ACTIVE_CALL = True
            elif not curr_active and prev_active:
                # Discord voice stream ended
                if os.path.exists(STATE_FILE):
                    close_call()
            prev_active = curr_active
        except Exception:
            pass
        time.sleep(1.5)

def run_monitor():
    global ACTIVE_CALL, LAST_CALL_TIME

    # Start audio monitor thread for outgoing/active voice calls
    t = threading.Thread(target=audio_monitor_loop, daemon=True)
    t.start()

    # Monitor DBus Notifications for incoming calls
    cmd = [
        "dbus-monitor",
        "--session",
        "interface='org.freedesktop.Notifications'"
    ]
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    except Exception as e:
        print("Failed to start dbus-monitor:", e, file=sys.stderr)
        return

    in_notify = False
    stage = -1
    app_name = ""
    summary = ""
    body = ""
    hints_image = ""

    for line in iter(proc.stdout.readline, ''):
        line = line.strip()
        if not line:
            continue

        if "member=Notify" in line:
            in_notify = True
            stage = 0
            app_name = ""
            summary = ""
            body = ""
            hints_image = ""
            continue

        if not in_notify:
            continue

        # Extract parameters
        if stage == 0:
            m = re.match(r'^string "(.*)"$', line)
            if m:
                app_name = m.group(1)
                stage = 1
                continue
        elif stage == 1:
            if line.startswith("uint32 "):
                stage = 2
                continue
        elif stage == 2:
            m = re.match(r'^string "(.*)"$', line)
            if m:
                icon_val = m.group(1)
                if icon_val.startswith("/") and os.path.isfile(icon_val):
                    hints_image = icon_val
                stage = 3
                continue
        elif stage == 3:
            m = re.match(r'^string "(.*)"$', line)
            if m:
                summary = m.group(1)
                stage = 4
                continue
        elif stage == 4:
            m = re.match(r'^string "(.*)"$', line)
            if m:
                body = m.group(1)
                stage = 5
                continue
        elif stage == 5:
            # Check hints for image-path
            if 'string "image-path"' in line or 'string "image_path"' in line:
                stage = 6
                continue
            # End of message detection (int32 timeout)
            if re.match(r'^int32 ', line):
                process_notification(app_name, summary, body, hints_image)
                in_notify = False
                stage = -1
                continue
        elif stage == 6:
            m = re.search(r'string "(.*)"', line)
            if m:
                hints_image = m.group(1)
                stage = 5
                continue

def process_notification(app_name, summary, body, hints_image):
    global ACTIVE_CALL, LAST_CALL_TIME
    lower_app = app_name.lower()
    lower_sum = summary.lower()
    lower_bod = body.lower()

    is_discord = any(x in lower_app for x in ("discord", "vesktop", "armcord", "webcord"))

    if is_discord:
        # Check if missed / ended / cancelled call
        ended_keywords = ("persa", "missed", "terminat", "ended", "annullat", "rifiutat", "chiusa")
        if any(k in lower_sum or k in lower_bod for k in ended_keywords):
            close_call()
            return

        # Check if incoming call
        call_keywords = ("call", "chiamat", "incoming", "avviato una chiamata")
        if any(k in lower_sum or k in lower_bod for k in call_keywords):
            caller = summary if summary else "Discord Call"
            sub = body if body else "Chiamata in arrivo..."
            avatar = ""

            if hints_image and os.path.isfile(hints_image):
                avatar = f"file://{hints_image}"
            else:
                resolved = resolve_avatar(caller)
                if resolved:
                    avatar = resolved

            ACTIVE_CALL = True
            LAST_CALL_TIME = time.time()
            send_ipc("incomingCall", caller, sub, avatar)

if __name__ == "__main__":
    run_monitor()
