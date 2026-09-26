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

os.makedirs(SCREENSHOT_DIR, exist_ok=True)
os.makedirs(GIF_DIR, exist_ok=True)

def run_cmd(cmd, shell=True, check=False):
    return subprocess.run(cmd, shell=shell, check=check, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

def focus_workspace(ws):
    run_cmd(f"hyprctl dispatch 'hl.dsp.focus({{ workspace = {ws} }})'")
    time.sleep(0.3)

def ipc_call(target, func, *args):
    arg_str = " ".join(f'"{a}"' if isinstance(a, str) else str(a) for a in args)
    cmd = f'quickshell -p "{QS_DIR}" ipc call {target} {func} {arg_str}'
    return run_cmd(cmd)

def record_and_capture(name, geometry, trigger_fn=None, reset_fn=None, duration=2.2, capture_delay=1.0, gif_extra_fn=None):
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
    # Give time for workspace switch alert to dismiss
    time.sleep(2.0)

    # Start 60 FPS recording
    rec_cmd = ["wf-recorder", "-r", "60", "-g", geometry, "-f", mp4_path, "-y"]
    rec_proc = subprocess.Popen(rec_cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(0.35)

    # Trigger feature
    if trigger_fn:
        trigger_fn()

    if gif_extra_fn:
        time.sleep(capture_delay * 0.5)
        gif_extra_fn()
        time.sleep(capture_delay * 0.5)
    else:
        time.sleep(capture_delay)

    # Take high-res settled screenshot
    print(f"   📸 Screenshot: {png_path}")
    run_cmd(f'grim -g "{geometry}" "{png_path}"')

    # Wait for full duration to capture complete animation
    remaining = duration - capture_delay - 0.35
    if remaining > 0:
        time.sleep(remaining)

    # Stop recording
    try:
        rec_proc.send_signal(signal.SIGINT)
        rec_proc.wait(timeout=4)
    except Exception:
        rec_proc.kill()

    # Reset feature
    if reset_fn:
        reset_fn()
        time.sleep(0.4)

    # Encode 60 FPS GIF
    print(f"   🎞️  Encoding 60 FPS GIF: {gif_path}")
    # Optimize palette for sharp 60fps animations
    ffmpeg_cmd = (
        f'ffmpeg -y -i "{mp4_path}" '
        f'-vf "fps=60,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" '
        f'"{gif_path}"'
    )
    run_cmd(ffmpeg_cmd)
    
    if os.path.exists(gif_path):
        size_kb = os.path.getsize(gif_path) / 1024
        print(f"   ✅ Done: {size_kb:.1f} KB")
    else:
        print(f"   ⚠️ GIF encoding failed for {name}")

def main():
    print("🚀 Starting Dynamic Island Asset Regeneration at 60 FPS")
    focus_workspace(9)
    time.sleep(1.0)
    
    # Ensure auto hide is disabled so island is always settled
    ipc_call("island", "disableAutoHide")
    time.sleep(0.5)

    # 1. Hardware Alerts
    record_and_capture("charging_demo", "740,0 440x100", 
                       trigger_fn=lambda: ipc_call("island", "testCharging", 85),
                       duration=2.5, capture_delay=1.0)
    # Duplicate charging_demo as charging.png
    run_cmd(f'cp "{SCREENSHOT_DIR}/charging_demo.png" "{SCREENSHOT_DIR}/charging.png"')

    record_and_capture("low_battery", "740,0 440x100",
                       trigger_fn=lambda: ipc_call("island", "testLowBattery", 15),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("silent_mode", "740,0 440x100",
                       trigger_fn=lambda: ipc_call("island", "testSilentRing", "true"),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("ring_mode", "740,0 440x100",
                       trigger_fn=lambda: ipc_call("island", "testSilentRing", "false"),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("osd_volume", "740,0 440x100",
                       trigger_fn=lambda: ipc_call("island", "testVolume", 65),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("osd_brightness", "740,0 440x100",
                       trigger_fn=lambda: ipc_call("island", "testBrightness", 80),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("workspace_switch", "740,0 440x100",
                       trigger_fn=lambda: ipc_call("island", "testWorkspace", 2),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("wifi_disconnect", "720,0 480x100",
                       trigger_fn=lambda: ipc_call("island", "testWifiDisconnect"),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("desktop_notification", "720,0 480x100",
                       trigger_fn=lambda: ipc_call("island", "testNotification", "WhatsApp", "Nuovo messaggio da Marco", "Ciao, ci vediamo dopo?"),
                       duration=2.5, capture_delay=1.0)

    # 2. Communications
    record_and_capture("discord_call_incoming", "720,0 480x100",
                       trigger_fn=lambda: ipc_call("island", "testDiscordCall", "St0rm"),
                       reset_fn=lambda: ipc_call("island", "closeCall"),
                       duration=2.8, capture_delay=1.0)

    record_and_capture("discord_call_ongoing", "720,0 480x100",
                       trigger_fn=lambda: ipc_call("island", "testDiscordCallOngoing", "St0rm"),
                       reset_fn=lambda: ipc_call("island", "closeCall"),
                       duration=2.8, capture_delay=1.0)

    # 3. Time & Info
    record_and_capture("custom_info_date", "600,0 720x100",
                       trigger_fn=lambda: ipc_call("island", "showCustom"),
                       reset_fn=lambda: ipc_call("island", "showClock"),
                       duration=2.6, capture_delay=1.0)

    # 4. Media & Lyrics (with live Spotify)
    record_and_capture("music_compact_island", "700,0 520x100",
                       trigger_fn=lambda: ipc_call("island", "showClock"),
                       duration=2.0, capture_delay=0.8)

    record_and_capture("synced_lyrics", "600,0 720x100",
                       trigger_fn=lambda: ipc_call("island", "showLyrics"),
                       reset_fn=lambda: ipc_call("island", "showClock"),
                       duration=3.0, capture_delay=1.2)

    # Expanded player: full geometry with concentric button (440,0 660x200)
    record_and_capture("expanded_media_player", "440,0 660x200",
                       trigger_fn=lambda: ipc_call("island", "togglePlayer"),
                       reset_fn=lambda: ipc_call("island", "togglePlayer"),
                       duration=3.2, capture_delay=1.2)

    # 5. Polkit FaceID Morph
    record_and_capture("polkit_auth", "720,0 480x260",
                       trigger_fn=lambda: ipc_call("island", "testPolkit"),
                       gif_extra_fn=lambda: ipc_call("island", "testPolkitSuccess"),
                       reset_fn=lambda: ipc_call("island", "closePolkit"),
                       duration=3.0, capture_delay=1.0)

    # 6. Control Center & Drawers
    record_and_capture("control_center_power_menu", "610,0 700x200",
                       trigger_fn=lambda: ipc_call("island", "togglePowerMenu"),
                       reset_fn=lambda: ipc_call("island", "togglePowerMenu"),
                       duration=2.5, capture_delay=1.0)

    record_and_capture("control_center", "720,0 480x560",
                       trigger_fn=lambda: ipc_call("island", "toggleControlCenter"),
                       reset_fn=lambda: ipc_call("island", "toggleControlCenter"),
                       duration=2.8, capture_delay=1.0)

    def trigger_wifi_drawer():
        ipc_call("island", "toggleControlCenter")
        time.sleep(0.4)
        ipc_call("island", "testDetailPanel", "wifi", "true")

    def reset_wifi_drawer():
        ipc_call("island", "testDetailPanel", "wifi", "false")
        time.sleep(0.2)
        ipc_call("island", "toggleControlCenter")

    record_and_capture("control_center_wifi_drawer", "525,0 870x560",
                       trigger_fn=trigger_wifi_drawer,
                       reset_fn=reset_wifi_drawer,
                       duration=3.0, capture_delay=1.2)

    def trigger_bt_drawer():
        ipc_call("island", "toggleControlCenter")
        time.sleep(0.4)
        ipc_call("island", "testDetailPanel", "bluetooth", "true")

    def reset_bt_drawer():
        ipc_call("island", "testDetailPanel", "bluetooth", "false")
        time.sleep(0.2)
        ipc_call("island", "toggleControlCenter")

    record_and_capture("control_center_bluetooth_drawer", "525,0 870x560",
                       trigger_fn=trigger_bt_drawer,
                       reset_fn=reset_bt_drawer,
                       duration=3.0, capture_delay=1.2)

    record_and_capture("notification_center", "720,0 480x420",
                       trigger_fn=lambda: ipc_call("island", "toggleNotificationCenter"),
                       reset_fn=lambda: ipc_call("island", "toggleNotificationCenter"),
                       duration=2.8, capture_delay=1.0)

    # 7. Island Popups
    record_and_capture("application_launcher", "380,0 1160x340",
                       trigger_fn=lambda: ipc_call("island", "toggleApplicationLauncher"),
                       reset_fn=lambda: ipc_call("island", "toggleApplicationLauncher"),
                       duration=2.8, capture_delay=1.0)

    record_and_capture("file_shelf", "380,0 1160x340",
                       trigger_fn=lambda: ipc_call("island", "toggleFileShelf"),
                       reset_fn=lambda: ipc_call("island", "toggleFileShelf"),
                       duration=2.8, capture_delay=1.0)

    record_and_capture("wallpaper_picker", "380,0 1160x340",
                       trigger_fn=lambda: ipc_call("island", "toggleWallpaperPicker"),
                       reset_fn=lambda: ipc_call("island", "toggleWallpaperPicker"),
                       duration=2.8, capture_delay=1.0)

    # 8. Screen Share Picker
    fifo_path = "/tmp/test_share_picker.fifo"
    if os.path.exists(fifo_path):
        os.remove(fifo_path)
    os.mkfifo(fifo_path)

    def trigger_screen_share():
        ipc_call("island", "promptScreenShareSelection", fifo_path)

    def reset_screen_share():
        run_cmd(f'echo "cancel" > "{fifo_path}" &')
        if os.path.exists(fifo_path):
            try:
                os.remove(fifo_path)
            except Exception:
                pass

    record_and_capture("screen_share_picker", "560,0 800x300",
                       trigger_fn=trigger_screen_share,
                       reset_fn=reset_screen_share,
                       duration=2.8, capture_delay=1.0)

    # 9. Settings App & Studio
    def trigger_settings_app():
        ipc_call("island", "showSettingsApp")
        time.sleep(0.3)
        ipc_call("island", "setSettingsCategory", 0)

    record_and_capture("settings_app", "440,170 1040x740",
                       trigger_fn=trigger_settings_app,
                       reset_fn=lambda: ipc_call("island", "toggleSettingsApp"),
                       duration=2.8, capture_delay=1.0)

    def trigger_studio():
        ipc_call("island", "showSettingsApp")
        time.sleep(0.3)
        ipc_call("island", "setSettingsCategory", 1)

    record_and_capture("settings_studio_canvas", "440,170 1040x740",
                       trigger_fn=trigger_studio,
                       reset_fn=lambda: ipc_call("island", "toggleSettingsApp"),
                       duration=2.8, capture_delay=1.0)

    # 10. Workspace Overview & Desktop
    record_and_capture("workspace_overview", "0,0 1920x1080",
                       trigger_fn=lambda: ipc_call("overview", "open"),
                       reset_fn=lambda: ipc_call("overview", "close"),
                       duration=2.8, capture_delay=1.0)

    # Full Desktop Still
    print(f"\n📸 Capturing full desktop on clean Workspace 9...")
    focus_workspace(9)
    time.sleep(2.0)
    run_cmd(f'grim "{SCREENSHOT_DIR}/full_desktop.png"')
    print(f"✅ Saved {SCREENSHOT_DIR}/full_desktop.png")

    # Restore workspace 1
    focus_workspace(1)
    print("\n🎉 ALL ASSETS REGENERATED SUCCESSFULLY AT 60 FPS!")

if __name__ == "__main__":
    main()
