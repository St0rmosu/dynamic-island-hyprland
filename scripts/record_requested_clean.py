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

def record_and_capture(name, geometry, trigger_fn=None, reset_fn=None, duration=2.6, capture_delay=1.0, gif_extra_fn=None, capture_screenshot=True):
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

    if gif_extra_fn:
        time.sleep(capture_delay * 0.5)
        gif_extra_fn()
        time.sleep(capture_delay * 0.5)
    else:
        time.sleep(capture_delay)

    if capture_screenshot:
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

    # Encode balanced 50 FPS GIF with ~1.22x speedup (setpts=0.82*PTS)
    print(f"   🎞️  Encoding calibrated GIF: {gif_path}")
    ffmpeg_cmd = (
        f'ffmpeg -y -i "{mp4_path}" '
        f'-filter_complex "[0:v]setpts=0.82*PTS,fps=50,split[s0][s1];[s0]palettegen=max_colors=128:stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" '
        f'"{gif_path}"'
    )
    run_cmd(ffmpeg_cmd)
    
    if os.path.exists(gif_path):
        size_kb = os.path.getsize(gif_path) / 1024
        print(f"   ✅ Done: {size_kb:.1f} KB")

def main():
    print("🚀 Starting Clean Asset Regeneration (NO SPOTIFY)...")
    run_cmd("pkill -9 spotify 2>/dev/null")
    set_screen_share_rule(True)
    try:
        focus_workspace(9)
        time.sleep(1.0)
        ipc_call("island", "disableAutoHide")
        ipc_call("island", "setHeadphonesHidden", True)
        time.sleep(0.5)

        # 1. Polkit Auth (FaceID)
        record_and_capture("polkit_auth", "720,0 480x260",
                           trigger_fn=lambda: ipc_call("island", "testPolkit"),
                           gif_extra_fn=lambda: ipc_call("island", "testPolkitSuccess"),
                           reset_fn=lambda: ipc_call("island", "closePolkit"),
                           duration=3.0, capture_delay=1.0)

        # 2. Wallpaper Picker
        record_and_capture("wallpaper_picker", "380,0 1160x340",
                           trigger_fn=lambda: ipc_call("island", "toggleWallpaperPicker"),
                           reset_fn=lambda: ipc_call("island", "toggleWallpaperPicker"),
                           duration=2.8, capture_delay=1.0)

        # 3. Application Launcher (ENLARGED: 480,0 960x490 to capture full 820x428 capsule)
        record_and_capture("application_launcher", "480,0 960x490",
                           trigger_fn=lambda: ipc_call("island", "toggleApplicationLauncher"),
                           reset_fn=lambda: ipc_call("island", "toggleApplicationLauncher"),
                           duration=2.8, capture_delay=1.0)

        # 4. AirDrop File Shelf
        record_and_capture("file_shelf", "380,0 1160x340",
                           trigger_fn=lambda: ipc_call("island", "toggleFileShelf"),
                           reset_fn=lambda: ipc_call("island", "toggleFileShelf"),
                           duration=2.8, capture_delay=1.0)

        # 5. Screen Share Picker
        fifo_path = "/tmp/test_share_picker_clean.fifo"
        if os.path.exists(fifo_path):
            os.remove(fifo_path)
        os.mkfifo(fifo_path)

        def trigger_share():
            ipc_call("island", "promptScreenShareSelection", fifo_path)

        def reset_share():
            try:
                fd = os.open(fifo_path, os.O_WRONLY | os.O_NONBLOCK)
                os.write(fd, b"cancel\n")
                os.close(fd)
            except Exception:
                pass
            ipc_call("island", "closeScreenSharePicker")
            if os.path.exists(fifo_path):
                try:
                    os.remove(fifo_path)
                except Exception:
                    pass

        record_and_capture("screen_share_picker", "560,0 800x300",
                           trigger_fn=trigger_share,
                           reset_fn=reset_share,
                           duration=2.6, capture_delay=1.0)

        # 6. Wi-Fi Drawer
        def trigger_wifi():
            ipc_call("island", "toggleControlCenter")
            time.sleep(0.4)
            ipc_call("island", "testDetailPanel", "wifi", "true")

        def reset_wifi():
            ipc_call("island", "testDetailPanel", "wifi", "false")
            time.sleep(0.2)
            ipc_call("island", "toggleControlCenter")

        record_and_capture("control_center_wifi_drawer", "525,0 870x560",
                           trigger_fn=trigger_wifi,
                           reset_fn=reset_wifi,
                           duration=3.0, capture_delay=1.2,
                           capture_screenshot=False)

        # 7. Bluetooth Drawer
        def trigger_bt():
            ipc_call("island", "toggleControlCenter")
            time.sleep(0.4)
            ipc_call("island", "testDetailPanel", "bluetooth", "true")

        def reset_bt():
            ipc_call("island", "testDetailPanel", "bluetooth", "false")
            time.sleep(0.2)
            ipc_call("island", "toggleControlCenter")

        record_and_capture("control_center_bluetooth_drawer", "525,0 870x560",
                           trigger_fn=trigger_bt,
                           reset_fn=reset_bt,
                           duration=3.0, capture_delay=1.2,
                           capture_screenshot=False)

        # 8. Power Menu
        record_and_capture("control_center_power_menu", "610,0 700x200",
                           trigger_fn=lambda: ipc_call("island", "togglePowerMenu"),
                           reset_fn=lambda: ipc_call("island", "togglePowerMenu"),
                           duration=2.5, capture_delay=1.0,
                           capture_screenshot=True)

        focus_workspace(1)
        print("\n🎉 ALL REQUESTED CLEAN ASSETS RE-RECORDED AT HIGH SNAPPINESS (NO SPOTIFY)!")
    finally:
        ipc_call("island", "setHeadphonesHidden", False)
        set_screen_share_rule(False)
        print("🔒 Restored headphones visibility and no_screen_share = true in rules.lua")

if __name__ == "__main__":
    main()
