#!/usr/bin/env python3
"""
Dynamic Island Notification Monitor
Captures notifications from standard DBus (org.freedesktop.Notifications.Notify)
and XDG Desktop Portal (org.freedesktop.portal.Notification.AddNotification).
Resolves real application names from DBus sender PID (e.g. WhatsApp Desktop).
Dispatches notifications directly to Quickshell via IPC.
"""

import subprocess
import os
import sys
import re
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
HOME_DIR = os.path.expanduser("~")
IPC_PATH = os.path.join(HOME_DIR, ".config/quickshell/dynamic-island")

# Cache sender pid -> process name
PID_APP_CACHE = {}

def get_process_name_for_pid(pid):
    if not pid or pid <= 0:
        return ""
    if pid in PID_APP_CACHE:
        return PID_APP_CACHE[pid]
    try:
        with open(f"/proc/{pid}/cmdline", "rb") as f:
            cmd = f.read().decode("utf-8", errors="ignore").replace("\x00", " ").strip()
            low = cmd.lower()
            res = ""
            if "whatsapp" in low:
                res = "WhatsApp"
            elif "discord" in low or "vesktop" in low or "armcord" in low:
                res = "Discord"
            elif "telegram" in low:
                res = "Telegram"
            elif "spotify" in low:
                res = "Spotify"
            elif "slack" in low:
                res = "Slack"
            elif "signal" in low:
                res = "Signal"
            elif "element" in low:
                res = "Element"
            elif "thunderbird" in low:
                res = "Thunderbird"
            elif "chrome" in low or "chromium" in low or "brave" in low:
                res = "Browser"
            else:
                parts = cmd.split()
                if parts:
                    res = parts[0].split("/")[-1].capitalize()
            if res:
                PID_APP_CACHE[pid] = res
                return res
    except Exception:
        pass
    return ""

def get_pid_for_dbus_sender(sender_id):
    if not sender_id:
        return 0
    try:
        res = subprocess.run(
            ["busctl", "--user", "call", "org.freedesktop.DBus", "/org/freedesktop/DBus",
             "org.freedesktop.DBus", "GetConnectionUnixProcessID", "s", sender_id],
            capture_output=True, text=True, timeout=1.0
        )
        if res.returncode == 0:
            parts = res.stdout.strip().split()
            if len(parts) >= 2 and parts[0] == "u":
                return int(parts[1])
    except Exception:
        pass
    return 0

# Deduplication tracking
LAST_NOTIFICATION_KEY = ""
LAST_NOTIFICATION_TIME = 0

def send_to_quickshell(app_name, summary, body, icon="", color=""):
    global LAST_NOTIFICATION_KEY, LAST_NOTIFICATION_TIME
    app_name = (app_name or "").strip()
    summary = (summary or "").strip()
    body = (body or "").strip()

    if not summary and not body:
        return

    now = time.time()
    dedup_key = f"{app_name}|{summary}|{body}"
    if dedup_key == LAST_NOTIFICATION_KEY and (now - LAST_NOTIFICATION_TIME) < 1.5:
        return
    LAST_NOTIFICATION_KEY = dedup_key
    LAST_NOTIFICATION_TIME = now

    cmd = [
        "quickshell", "ipc", "-p", IPC_PATH,
        "call", "island", "postNotification",
        app_name, summary, body, icon, color
    ]
    try:
        subprocess.run(cmd, timeout=2.0, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        sys.stderr.write(f"[NotificationMonitor] Error sending IPC: {e}\n")

def run_monitor():
    monitor_cmd = [
        "dbus-monitor", "--session",
        "type='method_call',member='Notify'",
        "type='method_call',member='AddNotification'"
    ]

    while True:
        try:
            proc = subprocess.Popen(
                monitor_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                text=True,
                bufsize=1
            )
        except Exception as e:
            sys.stderr.write(f"[NotificationMonitor] Failed to start dbus-monitor: {e}\n")
            time.sleep(3)
            continue

        current_method = None
        current_sender = None
        current_pid = 0
        method_lines = []

        for line in iter(proc.stdout.readline, ""):
            line_str = line.rstrip("\n")

            if "member=Notify" in line_str:
                current_method = "Notify"
                current_sender = None
                m = re.search(r"sender=([:\w\.]+)", line_str)
                if m:
                    current_sender = m.group(1)
                method_lines = []
                continue
            elif "member=AddNotification" in line_str:
                current_method = "AddNotification"
                current_sender = None
                m = re.search(r"sender=([:\w\.]+)", line_str)
                if m:
                    current_sender = m.group(1)
                method_lines = []
                continue
            elif line_str.startswith("method call ") or line_str.startswith("signal "):
                # Start of another message, process pending if any
                if current_method:
                    process_message(current_method, current_sender, method_lines)
                    current_method = None
                    method_lines = []
                continue

            if current_method:
                method_lines.append(line_str)
                # Check if we have collected enough lines
                if len(method_lines) > 50:
                    process_message(current_method, current_sender, method_lines)
                    current_method = None
                    method_lines = []

        try:
            proc.terminate()
            proc.wait(timeout=1)
        except Exception:
            pass
        time.sleep(1)

def extract_strings_from_lines(lines):
    strings = []
    for l in lines:
        trimmed = l.strip()
        if trimmed.startswith('string "') and trimmed.endswith('"'):
            # Basic unescape
            content = trimmed[8:-1].replace('\\"', '"').replace('\\\\', '\\')
            strings.append(content)
    return strings

def process_message(method, sender, lines):
    strings = extract_strings_from_lines(lines)

    # Check for desktop-entry or sender-pid in lines
    detected_app = ""
    sender_pid = 0
    for i, l in enumerate(lines):
        if "desktop-entry" in l:
            for j in range(i+1, min(i+4, len(lines))):
                m = re.search(r'string\s+"([^"]+)"', lines[j])
                if m:
                    desktop_entry = m.group(1).lower()
                    if "whatsapp" in desktop_entry:
                        detected_app = "WhatsApp"
                    elif "discord" in desktop_entry or "vesktop" in desktop_entry or "armcord" in desktop_entry:
                        detected_app = "Discord"
                    elif "telegram" in desktop_entry:
                        detected_app = "Telegram"
                    elif "spotify" in desktop_entry:
                        detected_app = "Spotify"
                    elif "slack" in desktop_entry:
                        detected_app = "Slack"
                    elif "signal" in desktop_entry:
                        detected_app = "Signal"
                    elif "thunderbird" in desktop_entry:
                        detected_app = "Thunderbird"
                    break
        if "sender-pid" in l:
            for j in range(i+1, min(i+4, len(lines))):
                m = re.search(r"(?:int64|uint32|int32)\s+(\d+)", lines[j])
                if m:
                    sender_pid = int(m.group(1))
                    break

    if not detected_app:
        if sender_pid <= 0 and sender:
            sender_pid = get_pid_for_dbus_sender(sender)
        detected_app = get_process_name_for_pid(sender_pid)

    if method == "Notify":
        # Signature: (app_name, replaces_id, app_icon, summary, body, ...)
        app_name = strings[0] if len(strings) > 0 else ""
        summary = strings[2] if len(strings) > 2 else (strings[1] if len(strings) > 1 else "")
        body = strings[3] if len(strings) > 3 else ""

        if len(strings) >= 4:
            app_name = strings[0]
            summary = strings[2]
            body = strings[3]
        elif len(strings) == 3:
            app_name = strings[0]
            summary = strings[1]
            body = strings[2]
        elif len(strings) == 2:
            summary = strings[0]
            body = strings[1]

        low_app = (app_name or "").lower()
        combo = (low_app + " " + summary + " " + body).lower()

        if "whatsapp" in combo:
            final_app = "WhatsApp"
        elif low_app in ("", "notification", "notify-send", "xdg-desktop-portal-gtk", "xdg-desktop-portal"):
            final_app = detected_app if detected_app else "Notification"
        else:
            final_app = detected_app if (detected_app and detected_app != "Browser") else app_name

        send_to_quickshell(final_app, summary, body)

    elif method == "AddNotification":
        # Arguments: string id, dict options { title: ..., body: ... }
        title = ""
        body = ""
        for i, l in enumerate(lines):
            if 'string "title"' in l:
                for j in range(i+1, min(i+4, len(lines))):
                    m = re.search(r'string\s+"([^"]+)"', lines[j])
                    if m:
                        title = m.group(1)
                        break
            elif 'string "body"' in l:
                for j in range(i+1, min(i+4, len(lines))):
                    m = re.search(r'string\s+"([^"]+)"', lines[j])
                    if m:
                        body = m.group(1)
                        break

        if not title and len(strings) > 1:
            title = strings[1]
        if not body and len(strings) > 2:
            body = strings[2]

        combo = (title + " " + body).lower()
        if "whatsapp" in combo:
            final_app = "WhatsApp"
        elif detected_app:
            final_app = detected_app
        else:
            final_app = "Notification"

        send_to_quickshell(final_app, title, body)

if __name__ == "__main__":
    run_monitor()
