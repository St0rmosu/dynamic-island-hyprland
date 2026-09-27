#!/usr/bin/env python3
"""
Hardware detector for Fingerprint Sensors on Linux / Hyprland.
Detects:
1. fprintd daemon via D-Bus / systemd / CLI
2. /sys/class/fprint /dev/fprint*
3. Known USB / SPI fingerprint reader devices (Goodix, Synaptics, Elan, Validity, etc.)
4. User demo mode flag ~/.config/dynamic-island/fingerprint_demo.txt or force demo param
"""

import sys
import os
import glob
import json
import subprocess

KNOWN_FINGERPRINT_VENDORS = {
    "27c6": "Goodix Fingerprint Sensor",
    "06cb": "Synaptics Touch Fingerprint",
    "04f3": "Elan Microelectronics Fingerprint",
    "138a": "Validity / Synaptics VFS",
    "1c7a": "EgisTec Fingerprint",
    "2808": "FocalTech Fingerprint",
    "0a5c": "Broadcom BCM Fingerprint",
    "3538": "SunplusIT Fingerprint",
    "10a5": "FPC Fingerprint Cards",
}

def check_fprintd():
    try:
        # Check via busctl or dbus-send if net.reactivated.Fprint exists
        res = subprocess.run(
            ["busctl", "status", "net.reactivated.Fprint"],
            capture_output=True, text=True, timeout=1.0
        )
        if res.returncode == 0:
            return True
    except Exception:
        pass

    try:
        res = subprocess.run(
            ["which", "fprintd-verify"],
            capture_output=True, text=True, timeout=1.0
        )
        if res.returncode == 0 and res.stdout.strip():
            return True
    except Exception:
        pass

    return False

def scan_sysfs():
    # 1. /sys/class/fprint
    if glob.glob("/sys/class/fprint*") or glob.glob("/dev/fprint*"):
        return True, "fprint device"

    # 2. USB Devices
    for vendor_file in glob.glob("/sys/bus/usb/devices/*/idVendor"):
        try:
            with open(vendor_file, "r") as f:
                vendor = f.read().strip().lower()
            if vendor in KNOWN_FINGERPRINT_VENDORS:
                return True, KNOWN_FINGERPRINT_VENDORS[vendor]
        except Exception:
            continue

    # 3. SPI Devices
    for uevent in glob.glob("/sys/bus/spi/devices/*/uevent"):
        try:
            with open(uevent, "r") as f:
                content = f.read().lower()
            if any(term in content for term in ["fingerprint", "fprint", "goodix"]):
                return True, "SPI Fingerprint Sensor"
        except Exception:
            continue

    return False, None

def check_pambiod():
    try:
        res = subprocess.run(["pgrep", "-x", "pambiod"], capture_output=True, text=True)
        if res.returncode == 0:
            return True, "PamBio (Telefono)"
    except Exception:
        pass
    home = os.path.expanduser("~")
    if os.path.exists("/etc/pambio") or os.path.exists(os.path.join(home, ".config/pambio")):
        return True, "PamBio (Telefono)"
    return False, None

def main():
    home = os.path.expanduser("~")
    demo_flag_path = os.path.join(home, ".config/dynamic-island/fingerprint_demo.txt")
    has_demo_flag = os.path.isfile(demo_flag_path)

    force_demo = "--demo" in sys.argv or has_demo_flag

    hw_detected, hw_name = scan_sysfs()
    has_service = check_fprintd()
    has_pambio, pambio_name = check_pambiod()

    dev_name = hw_name if hw_detected else (pambio_name if has_pambio else ("Sensore Touch ID (Simulato)" if force_demo else None))
    is_available = hw_detected or has_service or has_pambio or force_demo

    result = {
        "available": is_available,
        "hardware_detected": hw_detected or has_pambio,
        "device_name": dev_name,
        "fprintd_installed": has_service,
        "pambiod_active": has_pambio,
        "demo_mode": force_demo
    }

    print(json.dumps(result))

if __name__ == "__main__":
    main()
