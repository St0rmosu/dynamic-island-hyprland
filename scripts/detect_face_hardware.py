#!/usr/bin/env python3
"""
Hardware detector for Windows Hello / IR Cameras and Face Unlock (Howdy) on Linux.
Detects:
1. Howdy face recognition daemon / CLI (howdy, howdy-beta)
2. PAM Howdy module (pam_howdy.so)
3. Linux IR camera devices (/dev/video* with IR / Infrared descriptors)
4. linux-enable-ir-emitter configuration
5. User demo flag ~/.config/dynamic-island/face_demo.txt or --demo argument
"""

import sys
import os
import glob
import json
import subprocess

def check_howdy():
    # 1. CLI binary
    try:
        res = subprocess.run(["which", "howdy"], capture_output=True, text=True, timeout=1.0)
        if res.returncode == 0 and res.stdout.strip():
            return True, "Howdy Face Recognition"
    except Exception:
        pass

    # 2. PAM module
    pam_locations = [
        "/lib/security/pam_howdy.so",
        "/usr/lib/security/pam_howdy.so",
        "/usr/local/lib/security/pam_howdy.so"
    ]
    for loc in pam_locations:
        if os.path.isfile(loc):
            return True, "Howdy PAM Module"

    # 3. Config directory
    if os.path.isdir("/etc/howdy"):
        return True, "Howdy Configuration"

    return False, None

def scan_ir_cameras():
    # Scan /sys/class/video4linux/*/name
    for name_file in glob.glob("/sys/class/video4linux/video*/name"):
        try:
            with open(name_file, "r") as f:
                name = f.read().strip()
            name_lower = name.lower()
            ir_keywords = ["ir camera", "infrared", "ir-camera", "windows hello", "rgb-ir", "ir webcam", "face auth"]
            if any(kw in name_lower for kw in ir_keywords):
                return True, name
        except Exception:
            continue

    # Check udevadm property for IR camera
    for dev in glob.glob("/dev/video*"):
        try:
            res = subprocess.run(["udevadm", "info", "-q", "property", "-n", dev], capture_output=True, text=True, timeout=1.0)
            if res.returncode == 0:
                txt = res.stdout.lower()
                if "infrared" in txt or "ir_camera" in txt or "windows_hello" in txt:
                    return True, "Fotocamera IR (Windows Hello)"
        except Exception:
            continue

    return False, None

def check_ir_emitter():
    try:
        res = subprocess.run(["which", "linux-enable-ir-emitter"], capture_output=True, text=True, timeout=1.0)
        if res.returncode == 0 and res.stdout.strip():
            return True, "linux-enable-ir-emitter"
    except Exception:
        pass
    return False, None

def main():
    home = os.path.expanduser("~")
    demo_flag_path = os.path.join(home, ".config/dynamic-island/face_demo.txt")
    has_demo_flag = os.path.isfile(demo_flag_path)
    force_demo = "--demo" in sys.argv or has_demo_flag

    has_howdy, howdy_name = check_howdy()
    has_ir_cam, ir_cam_name = scan_ir_cameras()
    has_emitter, emitter_name = check_ir_emitter()

    hw_detected = has_ir_cam or has_emitter
    is_available = has_howdy or hw_detected or force_demo

    device_name = ir_cam_name if has_ir_cam else (howdy_name if has_howdy else ("Face ID (Simulato)" if force_demo else None))

    result = {
        "available": is_available,
        "hardware_detected": hw_detected,
        "howdy_installed": has_howdy,
        "device_name": device_name,
        "ir_camera_detected": has_ir_cam,
        "demo_mode": force_demo
    }

    print(json.dumps(result))

if __name__ == "__main__":
    main()
