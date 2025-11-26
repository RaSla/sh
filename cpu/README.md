# Setup CPU

Script for setting up CPU (freq & governor).

Defaults:

* governor = `powersafe`
* max_cpu_freq = BASE_CPU_FREQ (w/o "Turbo Boost")

## Install

* Copy 2 files to the `/opt` folder. Example:

```shell
# cd /opt
# wget https://github.com/RaSla/sh/raw/main/cpu/cpu-setup.service
# wget https://github.com/RaSla/sh/raw/main/cpu/cpu-setup.sh
# chmod +x cpu-setup.sh
```

* (Optional) edit `cpu-setup.sh` - see `Configure` section
* run commands as ROOT:

```shell
# ln -sf /opt/cpu-setup.service /lib/systemd/system/
# systemctl daemon-reload
# systemctl start cpu-setup
# systemctl enable cpu-setup
# systemctl status cpu-setup
# journalctl -u cpu-setup
```

## Configure

* Get CPU info: max CPU-freq & governor, for example:

```shell
# cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
performance powersave

# cat /sys/devices/system/cpu/cpu0/cpufreq/base_frequency
2400000
# cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
4200000
# head /proc/cpuinfo 
processor       : 0
vendor_id       : GenuineIntel
cpu family      : 6
model           : 140
model name      : 11th Gen Intel(R) Core(TM) i5-1135G7 @ 2.40GHz
stepping        : 1
microcode       : 0xb6
cpu MHz         : 400.000
cache size      : 8192 KB
physical id     : 0
```

* Define vars in `cpu-setup.sh`, for example:

```shell
## Comment CPU_GOVERNOR, if you don't want to change CPU Governor 
CPU_GOVERNOR="powersave"
CPU_MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/base_frequency)
## uncomment & edit, if you want to manually set the maximum frequency limit
#CPU_MAX_FREQ=2600000
```

* Run script after edit: `sudo /opt/cpu-setup.sh` or `systemctl start cpu-setup`
