#!/usr/bin/env python3
import sys
import subprocess
import json
import os
import time

STATE_FILE = "/tmp/tide_discord_call_ongoing"

def run_hypr_lua(code):
    cmd = ["hyprctl", "repl", code]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
        return res.stdout.strip()
    except Exception as e:
        return str(e)

def find_discord_window():
    try:
        res = subprocess.run(["hyprctl", "clients", "-j"], capture_output=True, text=True, timeout=2)
        clients = json.loads(res.stdout)
        for client in clients:
            cls = (client.get("class") or "").lower()
            title = (client.get("title") or "").lower()
            if any(x in cls for x in ("discord", "vesktop", "armcord", "webcord")) or "discord" in title:
                return client
    except Exception:
        pass
    return None

def accept_call():
    # Mark ongoing call state so monitor doesn't kill the island when notification closes
    try:
        with open(STATE_FILE, "w") as f:
            f.write(str(time.time()))
    except Exception:
        pass

    # 1. Invoke SwayNC action 0 if notification exists
    try:
        subprocess.run(["swaync-client", "--action", "0"], timeout=1, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # 2. Target Discord window
    win = find_discord_window()
    if win:
        addr = win.get("address", "")
        # Focus Discord so user can participate in call and see UI
        if addr:
            run_hypr_lua(f'hl.dispatch(hl.dsp.focus({{ window = "address:{addr}" }}))')
            time.sleep(0.06)
            run_hypr_lua(f'hl.dispatch(hl.dsp.send_shortcut({{ mods = "ctrl", key = "Return", window = "address:{addr}" }}))')
        else:
            run_hypr_lua('hl.dispatch(hl.dsp.focus({ window = "class:discord" }))')
            time.sleep(0.06)
            run_hypr_lua('hl.dispatch(hl.dsp.send_shortcut({ mods = "ctrl", key = "Return", window = "class:discord" }))')

    # 3. Fallback wtype keypress
    try:
        subprocess.run(["wtype", "-M", "ctrl", "-k", "Return", "-m", "ctrl"], timeout=1, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # 4. Notify quickshell island
    ipc_path = os.path.expanduser("~/.config/quickshell/tide-island")
    subprocess.run(["quickshell", "ipc", "-p", ipc_path, "call", "island", "callAccepted"], timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def decline_call():
    # Remove ongoing state
    try:
        if os.path.exists(STATE_FILE):
            os.remove(STATE_FILE)
    except Exception:
        pass

    # 1. Close notification in SwayNC
    try:
        subprocess.run(["swaync-client", "--close-latest"], timeout=1, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # 2. Target Discord window with Escape and Ctrl+Shift+D (disconnect)
    win = find_discord_window()
    if win:
        addr = win.get("address", "")
        if addr:
            # Escape to decline incoming call
            run_hypr_lua(f'hl.dispatch(hl.dsp.send_shortcut({{ mods = "", key = "Escape", window = "address:{addr}" }}))')
            # Ctrl+Shift+D to hangup voice call if connected
            run_hypr_lua(f'hl.dispatch(hl.dsp.send_shortcut({{ mods = "ctrl shift", key = "D", window = "address:{addr}" }}))')
        else:
            run_hypr_lua('hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "Escape", window = "class:discord" }))')
            run_hypr_lua('hl.dispatch(hl.dsp.send_shortcut({ mods = "ctrl shift", key = "D", window = "class:discord" }))')

    # 3. Fallback wtype
    try:
        subprocess.run(["wtype", "-k", "Escape"], timeout=1, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        pass

    # 4. Close call on quickshell island
    ipc_path = os.path.expanduser("~/.config/quickshell/tide-island")
    subprocess.run(["quickshell", "ipc", "-p", ipc_path, "call", "island", "closeCall"], timeout=2, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def focus_discord():
    win = find_discord_window()
    if win:
        addr = win.get("address", "")
        if addr:
            run_hypr_lua(f'hl.dispatch(hl.dsp.focus({{ window = "address:{addr}" }}))')
        else:
            run_hypr_lua('hl.dispatch(hl.dsp.focus({ window = "class:discord" }))')

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    act = sys.argv[1].lower()
    if act in ("accept", "answer"):
        accept_call()
    elif act in ("decline", "reject", "hangup", "end", "close"):
        decline_call()
    elif act == "focus":
        focus_discord()
