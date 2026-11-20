#!/usr/bin/env bash
PROFILE="$1"
[ -z "$PROFILE" ] && exit 0

# 1. Try powerprofilesctl first (standard systemd power-profiles-daemon)
if command -v powerprofilesctl >/dev/null 2>&1; then
    if powerprofilesctl set "$PROFILE" 2>/dev/null; then
        exit 0
    fi
fi

# 2. Fallback: CPU energy performance preference (EPP)
case "$PROFILE" in
    power-saver)
        EPP="power"
        GOV="powersave"
        ;;
    performance)
        EPP="performance"
        GOV="performance"
        ;;
    balanced|*)
        EPP="balance_performance"
        GOV="ondemand"
        ;;
esac

# Try writing to sysfs EPP if writable
for p in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
    [ -w "$p" ] && echo "$EPP" > "$p" 2>/dev/null || true
done

# Try writing to scaling_governor if writable
for g in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -w "$g" ] && echo "$GOV" > "$g" 2>/dev/null || true
done

exit 0
