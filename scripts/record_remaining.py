#!/usr/bin/env python3
import os
import sys
import time
import subprocess
import signal

HOME = os.path.expanduser("~")
QS_DIR = os.environ.get("QUICKSHELL_DIR", os.path.join(HOME, ".config/quickshell/dynamic-island"))
PROJECT_DIR = os.environ.get("DYNAMIC_ISLAND_PROJECT_DIR", QS_DIR)
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

def record_and_capture(name, geometry, trigger_fn=None, reset_fn=None, duration=2.5, capture_delay=1.0):
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
    focus_workspace(9)
    time.sleep(1.0)
    ipc_call("island", "disableAutoHide")

    # 1. Screen Share Picker
    fifo_path = "/tmp/test_share_picker.fifo"
    if os.path.exists(fifo_path):
        os.remove(fifo_path)
    os.mkfifo(fifo_path)

    def trigger_share():
        ipc_call("island", "promptScreenShareSelection", fifo_path)

    def reset_share():
        # Open in non-blocking mode to write cancel and close
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
                       duration=2.5, capture_delay=1.0)

    # 2. Settings App
    def trigger_settings_app():
        ipc_call("island", "showSettingsApp")
        time.sleep(0.3)
        ipc_call("island", "setSettingsCategory", 0)

    record_and_capture("settings_app", "440,170 1040x740",
                       trigger_fn=trigger_settings_app,
                       reset_fn=lambda: ipc_call("island", "toggleSettingsApp"),
                       duration=2.8, capture_delay=1.0)

    # 3. Settings Studio Canvas
    def trigger_studio():
        ipc_call("island", "showSettingsApp")
        time.sleep(0.3)
        ipc_call("island", "setSettingsCategory", 1)

    record_and_capture("settings_studio_canvas", "440,170 1040x740",
                       trigger_fn=trigger_studio,
                       reset_fn=lambda: ipc_call("island", "toggleSettingsApp"),
                       duration=2.8, capture_delay=1.0)

    # 4. Workspace Overview
    record_and_capture("workspace_overview", "0,0 1920x1080",
                       trigger_fn=lambda: ipc_call("overview", "open"),
                       reset_fn=lambda: ipc_call("overview", "close"),
                       duration=2.8, capture_delay=1.0)

    # 5. Full Desktop Still
    print(f"\n📸 Capturing full desktop on clean Workspace 9...")
    focus_workspace(9)
    time.sleep(2.0)
    run_cmd(f'grim "{SCREENSHOT_DIR}/full_desktop.png"')
    print(f"✅ Saved {SCREENSHOT_DIR}/full_desktop.png")

    focus_workspace(1)
    print("\n🎉 ALL REMAINING ASSETS RECORDED SUCCESSFULLY!")

if __name__ == "__main__":
    main()
