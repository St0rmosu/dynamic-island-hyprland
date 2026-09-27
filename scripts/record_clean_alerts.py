#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import signal

PROJECT_DIR = "/home/lollo/Progetti/dynamic-island-hyprland"
QS_DIR = "/home/lollo/.config/quickshell/dynamic-island"
SCREENSHOT_DIR = os.path.join(PROJECT_DIR, "assets/screenshots")
GIF_DIR = os.path.join(PROJECT_DIR, "assets/gifs")

def run_cmd(cmd, shell=True, check=False):
    return subprocess.run(cmd, shell=shell, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

def focus_workspace(ws):
    run_cmd(f"hyprctl dispatch 'hl.dsp.focus({{ workspace = {ws} }})'")
    time.sleep(0.3)

def ipc_call(target, func, *args):
    arg_str = " ".join(f'"{a}"' if isinstance(a, str) else str(a) for a in args)
    cmd = f'quickshell -p "{QS_DIR}" ipc call {target} {func} {arg_str}'
    return run_cmd(cmd)

def set_screen_share_rule(enable):
    val = "false" if enable else "true"
    run_cmd(f"sed -i 's/no_screen_share = .*/no_screen_share = {val},/g' /home/lollo/.config/hypr/moduli/rules.lua")
    time.sleep(0.3)

def record_and_capture(name, geometry, trigger_fn=None, reset_fn=None, duration=2.5, capture_delay=0.9):
    print(f"\n==========================================")
    print(f"🎬 Recording & Capturing: {name}")
    print(f"   Geometry: {geometry}, Duration: {duration}s")
    print(f"==========================================")
    
    mp4_path = f"/tmp/rec_{name}.mp4"
    png_path = os.path.join(SCREENSHOT_DIR, f"{name}.png")
    gif_path = os.path.join(GIF_DIR, f"{name}.gif")
    
    if os.path.exists(mp4_path):
        os.remove(mp4_path)

    focus_workspace(9)
    run_cmd("hyprctl dispatch 'hl.dsp.cursor.move({ x = 0, y = 1000 })'")
    time.sleep(2.0)

    # Start 60 FPS recording
    rec_cmd = ["wf-recorder", "-r", "60", "-g", geometry, "-f", mp4_path, "-y"]
    rec_proc = subprocess.Popen(rec_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.35)

    if trigger_fn:
        trigger_fn()

    time.sleep(capture_delay)

    # High-res screenshot
    print(f"   📸 Screenshot: {png_path}")
    run_cmd(f'grim -g "{geometry}" "{png_path}"')

    remaining = duration - capture_delay - 0.35
    if remaining > 0:
        time.sleep(remaining)

    try:
        rec_proc.send_signal(signal.SIGINT)
        rec_proc.wait(timeout=4)
    except Exception:
        rec_proc.kill()

    if reset_fn:
        reset_fn()
        time.sleep(0.4)

    print(f"   🎞️  Encoding 60 FPS GIF: {gif_path}")
    ffmpeg_cmd = (
        f'ffmpeg -y -i "{mp4_path}" '
        f'-vf "fps=60,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" '
        f'"{gif_path}"'
    )
    run_cmd(ffmpeg_cmd)
    
    if os.path.exists(gif_path):
        size_kb = os.path.getsize(gif_path) / 1024
        print(f"   ✅ Done: {size_kb:.1f} KB")

def main():
    print("🚀 Starting Clean Hardware Alerts & Notifications Recording at 60 FPS (NO SPOTIFY)...")
    set_screen_share_rule(True)
    try:
        focus_workspace(9)
        time.sleep(1.0)
        ipc_call("island", "disableAutoHide")
        ipc_call("island", "setHeadphonesHidden", True)
        time.sleep(0.5)

        # 1. Section 2 Hardware Alerts (requested by user in screenshot 2)
        record_and_capture("charging_demo", "740,0 440x100", 
                           trigger_fn=lambda: ipc_call("island", "testCharging", 85),
                           duration=2.5, capture_delay=0.9)
        run_cmd(f'cp "{SCREENSHOT_DIR}/charging_demo.png" "{SCREENSHOT_DIR}/charging.png"')

        record_and_capture("low_battery", "740,0 440x100",
                           trigger_fn=lambda: ipc_call("island", "testLowBattery", 15),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("silent_mode", "740,0 440x100",
                           trigger_fn=lambda: ipc_call("island", "testSilentRing", "true"),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("ring_mode", "740,0 440x100",
                           trigger_fn=lambda: ipc_call("island", "testSilentRing", "false"),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("osd_volume", "740,0 440x100",
                           trigger_fn=lambda: ipc_call("island", "testVolume", 65),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("osd_brightness", "740,0 440x100",
                           trigger_fn=lambda: ipc_call("island", "testBrightness", 80),
                           duration=2.5, capture_delay=0.9)

        # 2. Other alert capsules that had Spotify pill attached
        record_and_capture("workspace_switch", "740,0 440x100",
                           trigger_fn=lambda: ipc_call("island", "testWorkspace", 2),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("wifi_disconnect", "720,0 480x100",
                           trigger_fn=lambda: ipc_call("island", "testWifiDisconnect"),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("desktop_notification", "720,0 480x100",
                           trigger_fn=lambda: ipc_call("island", "testNotification", "WhatsApp", "Nuovo messaggio da Marco", "Ciao, ci vediamo dopo?"),
                           duration=2.5, capture_delay=0.9)

        record_and_capture("discord_call_incoming", "720,0 480x100",
                           trigger_fn=lambda: ipc_call("island", "testDiscordCall", "St0rm"),
                           reset_fn=lambda: ipc_call("island", "closeCall"),
                           duration=2.8, capture_delay=0.9)

        record_and_capture("discord_call_ongoing", "720,0 480x100",
                           trigger_fn=lambda: ipc_call("island", "testDiscordCallOngoing", "St0rm"),
                           reset_fn=lambda: ipc_call("island", "closeCall"),
                           duration=2.8, capture_delay=0.9)

        focus_workspace(1)
        print("\n🎉 ALL HARDWARE ALERTS AND NOTIFICATIONS RE-RECORDED CLEANLY AT 60 FPS!")
    finally:
        ipc_call("island", "setHeadphonesHidden", False)
        set_screen_share_rule(False)
        print("🔒 Restored headphones visibility and no_screen_share = true in rules.lua")

if __name__ == "__main__":
    main()
