#!/bin/sh
CPU_GOVERNOR="powersave"
CPU_MAX_FREQ=2600000

echo "* Available CPU governors:"
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
if [ -n "$CPU_GOVERNOR" ]; then
    echo "* Setting CPU scaling_governor to '$CPU_GOVERNOR'"
fi

echo -n "** Current CPU Max frequency: "
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq

echo "* Setting CPU Max frequency to '$CPU_MAX_FREQ' for all CPU cores:"
for i in /sys/devices/system/cpu/cpu*/cpufreq; do
    if [ -n "$CPU_GOVERNOR" ]; then
        echo $CPU_GOVERNOR > $i/scaling_governor
    fi
    echo $CPU_MAX_FREQ > $i/scaling_max_freq
    echo -n "$i/scaling_max_freq: "
    cat $i/scaling_max_freq
done
