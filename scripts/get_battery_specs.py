#!/usr/bin/env python3
import json
import subprocess
import glob
import os
import re

def parse_val(s):
    if not s:
        return None
    return s.strip().replace(',', '.')

def get_battery_specs():
    specs = {
        "percentage": 100,
        "state": "Discharging",
        "status_text": "Discharging",
        "is_charging": false if False else False,
        "capacity_full": "--",
        "capacity_design": "--",
        "health": "--",
        "rate": "--",
        "time_remaining": "",
        "limit": "--",
        "cycles": "--",
        "vendor": "",
        "model": "",
        "technology": "",
        "profile": "balanced"
    }

    # 1. First probe sysfs (/sys/class/power_supply/BAT*)
    bat_paths = sorted(glob.glob('/sys/class/power_supply/BAT*'))
    sysfs_data = {}
    if bat_paths:
        bat_dir = bat_paths[0]
        for name in os.listdir(bat_dir):
            p = os.path.join(bat_dir, name)
            if os.path.isfile(p):
                try:
                    with open(p, 'r') as fp:
                        sysfs_data[name] = fp.read().strip()
                except Exception:
                    pass

    # Read basic sysfs values
    if sysfs_data:
        if "status" in sysfs_data:
            specs["state"] = sysfs_data["status"]
            specs["status_text"] = sysfs_data["status"]
            if sysfs_data["status"].lower() in ["charging"]:
                specs["is_charging"] = True

        if "capacity" in sysfs_data:
            try:
                specs["percentage"] = int(sysfs_data["capacity"])
            except ValueError:
                pass

        if "manufacturer" in sysfs_data and sysfs_data["manufacturer"]:
            specs["vendor"] = sysfs_data["manufacturer"]
        if "model_name" in sysfs_data and sysfs_data["model_name"]:
            specs["model"] = sysfs_data["model_name"]
        if "technology" in sysfs_data and sysfs_data["technology"]:
            specs["technology"] = sysfs_data["technology"]

        # Calculate energy and health
        v_now = float(sysfs_data.get("voltage_now", 0) or 0) / 1e6
        v_min = float(sysfs_data.get("voltage_min_design", 0) or 0) / 1e6
        volt = v_min if v_min > 0 else (v_now if v_now > 0 else 11.5)

        # Capacity full design
        if "energy_full_design" in sysfs_data:
            efd = float(sysfs_data["energy_full_design"]) / 1e6
            specs["capacity_design"] = f"{efd:.1f}Wh"
        elif "charge_full_design" in sysfs_data:
            cfd = (float(sysfs_data["charge_full_design"]) / 1e6) * volt
            specs["capacity_design"] = f"{cfd:.1f}Wh"

        # Capacity full
        ef = 0
        if "energy_full" in sysfs_data:
            ef = float(sysfs_data["energy_full"]) / 1e6
            specs["capacity_full"] = f"{ef:.1f}Wh"
        elif "charge_full" in sysfs_data:
            ef = (float(sysfs_data["charge_full"]) / 1e6) * volt
            specs["capacity_full"] = f"{ef:.1f}Wh"

        # Battery Health %
        if "energy_full_design" in sysfs_data and "energy_full" in sysfs_data:
            try:
                h = (float(sysfs_data["energy_full"]) / float(sysfs_data["energy_full_design"])) * 100
                specs["health"] = f"{round(h)}%"
            except ZeroDivisionError:
                pass
        elif "charge_full_design" in sysfs_data and "charge_full" in sysfs_data:
            try:
                h = (float(sysfs_data["charge_full"]) / float(sysfs_data["charge_full_design"])) * 100
                specs["health"] = f"{round(h)}%"
            except ZeroDivisionError:
                pass

        # Power rate
        if "power_now" in sysfs_data:
            p_now = float(sysfs_data["power_now"]) / 1e6
            specs["rate"] = f"{p_now:.1f}W"
        elif "current_now" in sysfs_data and v_now > 0:
            c_now = float(sysfs_data["current_now"]) / 1e6
            p_now = c_now * v_now
            specs["rate"] = f"{p_now:.1f}W"

        # Threshold
        start_th = sysfs_data.get("charge_control_start_threshold")
        end_th = sysfs_data.get("charge_control_end_threshold")
        if start_th and end_th and (int(start_th) > 0 or int(end_th) > 0):
            specs["limit"] = f"{start_th}-{end_th}%"

        # Cycles
        if "cycle_count" in sysfs_data and sysfs_data["cycle_count"] not in ["0", ""]:
            specs["cycles"] = sysfs_data["cycle_count"]

        # Sysfs fallback for time remaining
        if not specs["time_remaining"]:
            try:
                if "charge_now" in sysfs_data and "current_now" in sysfs_data:
                    c_now = float(sysfs_data["charge_now"])
                    cur = float(sysfs_data["current_now"])
                    if cur > 0:
                        if specs["is_charging"] and "charge_full" in sysfs_data:
                            c_full = float(sysfs_data["charge_full"])
                            rem_h = max(0.0, (c_full - c_now) / cur)
                            specs["time_remaining"] = f"{rem_h:.1f} hours"
                        else:
                            rem_h = c_now / cur
                            specs["time_remaining"] = f"{rem_h:.1f} hours"
                elif "energy_now" in sysfs_data and "power_now" in sysfs_data:
                    e_now = float(sysfs_data["energy_now"])
                    p_now = float(sysfs_data["power_now"])
                    if p_now > 0:
                        if specs["is_charging"] and "energy_full" in sysfs_data:
                            e_full = float(sysfs_data["energy_full"])
                            rem_h = max(0.0, (e_full - e_now) / p_now)
                            specs["time_remaining"] = f"{rem_h:.1f} hours"
                        else:
                            rem_h = e_now / p_now
                            specs["time_remaining"] = f"{rem_h:.1f} hours"
            except Exception:
                pass

    # 2. Query UPower for enhanced metrics (thresholds, time remaining, cycles, accurate rate)
    try:
        up_out = subprocess.check_output(['upower', '-e'], text=True, stderr=subprocess.DEVNULL)
        bat_dev = [line.strip() for line in up_out.splitlines() if 'battery' in line]
        if bat_dev:
            info_out = subprocess.check_output(['upower', '-i', bat_dev[0]], text=True, stderr=subprocess.DEVNULL)
            up_dict = {}
            for line in info_out.splitlines():
                if ':' in line:
                    k, v = line.split(':', 1)
                    up_dict[k.strip()] = v.strip()

            if "state" in up_dict:
                specs["state"] = up_dict["state"].capitalize()
                specs["status_text"] = up_dict["state"].capitalize()
                specs["is_charging"] = up_dict["state"].lower() in ["charging"]

            if "percentage" in up_dict:
                p_str = up_dict["percentage"].replace('%', '').strip()
                try:
                    specs["percentage"] = int(float(parse_val(p_str)))
                except ValueError:
                    pass

            if "energy-full-design" in up_dict and up_dict["energy-full-design"] != "0 Wh":
                raw = parse_val(up_dict["energy-full-design"].replace(" Wh", ""))
                try:
                    specs["capacity_design"] = f"{float(raw):.1f}Wh"
                except Exception:
                    specs["capacity_design"] = up_dict["energy-full-design"]

            if "energy-full" in up_dict and up_dict["energy-full"] != "0 Wh":
                raw = parse_val(up_dict["energy-full"].replace(" Wh", ""))
                try:
                    specs["capacity_full"] = f"{float(raw):.1f}Wh"
                except Exception:
                    specs["capacity_full"] = up_dict["energy-full"]

            if "capacity" in up_dict:
                cap_str = parse_val(up_dict["capacity"].replace('%', ''))
                try:
                    specs["health"] = f"{round(float(cap_str))}%"
                except Exception:
                    pass

            if "energy-rate" in up_dict and up_dict["energy-rate"] != "0 W":
                raw = parse_val(up_dict["energy-rate"].replace(" W", ""))
                try:
                    specs["rate"] = f"{float(raw):.1f}W"
                except Exception:
                    specs["rate"] = up_dict["energy-rate"]

            if "time to empty" in up_dict:
                specs["time_remaining"] = up_dict["time to empty"]
            elif "time to full" in up_dict:
                specs["time_remaining"] = up_dict["time to full"]

            if specs["cycles"] == "--" and "charge-cycles" in up_dict and up_dict["charge-cycles"] != "N/A":
                specs["cycles"] = up_dict["charge-cycles"]

            start_t = up_dict.get("charge-start-threshold")
            end_t = up_dict.get("charge-end-threshold")
            if start_t and end_t:
                specs["limit"] = f"{start_t.replace('%','')}-{end_t.replace('%','')}%"

            if not specs["vendor"] and "vendor" in up_dict:
                specs["vendor"] = up_dict["vendor"]
            if not specs["model"] and "model" in up_dict:
                specs["model"] = up_dict["model"]
            if not specs["technology"] and "technology" in up_dict:
                specs["technology"] = up_dict["technology"]
    except Exception:
        pass

    # 3. Accumulated cycles fallback from UPower history files if firmware reports 0 cycles
    if specs["cycles"] in ["--", "0", "N/A"]:
        try:
            cache_file = os.path.expanduser('~/.local/state/dynamic-island/battery_cycles.json')
            cached_cycles = 0
            if os.path.exists(cache_file):
                try:
                    with open(cache_file) as f:
                        cached_cycles = json.load(f).get('cycles', 0)
                except Exception:
                    pass

            total_charge = 0
            prev_val = None
            up_files = glob.glob('/var/lib/upower/history-charge-*.dat')
            for fpath in up_files:
                try:
                    with open(fpath) as f:
                        for line in f:
                            parts = line.strip().split()
                            if len(parts) >= 2:
                                val = float(parts[1].replace(',', '.'))
                                if prev_val is not None and val > prev_val:
                                    total_charge += (val - prev_val)
                                prev_val = val
                except Exception:
                    pass

            if total_charge > 0:
                cycles_val = max(cached_cycles, max(1, int(round(total_charge / 100.0))))
                specs["cycles"] = str(cycles_val)
                try:
                    os.makedirs(os.path.dirname(cache_file), exist_ok=True)
                    with open(cache_file, 'w') as f:
                        json.dump({'cycles': cycles_val, 'total_charged_pct': total_charge}, f)
                except Exception:
                    pass
            elif cached_cycles > 0:
                specs["cycles"] = str(cached_cycles)
        except Exception:
            pass

    # 4. Power Profile
    try:
        pp = subprocess.check_output(['powerprofilesctl', 'get'], text=True, stderr=subprocess.DEVNULL).strip()
        if pp:
            specs["profile"] = pp
    except Exception:
        # Fallback to EPP or Governor
        try:
            epp_path = '/sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference'
            gov_path = '/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor'
            if os.path.exists(epp_path):
                with open(epp_path) as f:
                    epp = f.read().strip().lower()
                    if 'power' in epp:
                        specs["profile"] = "power-saver"
                    elif 'perf' in epp:
                        specs["profile"] = "performance"
                    else:
                        specs["profile"] = "balanced"
            elif os.path.exists(gov_path):
                with open(gov_path) as f:
                    gov = f.read().strip().lower()
                    if 'powersave' in gov:
                        specs["profile"] = "power-saver"
                    elif 'performance' in gov:
                        specs["profile"] = "performance"
                    else:
                        specs["profile"] = "balanced"
        except Exception:
            pass

    return specs

if __name__ == "__main__":
    print(json.dumps(get_battery_specs()))
