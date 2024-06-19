# Setup CPU

Script for setting up CPU (freq & governor)

## Install

* Copy 2 files to the `/opt` folder. Example:

```shell
# cd /opt
# wget https://github.com/RaSla/sh/raw/main/cpu/set-cpufreq.service
# wget https://github.com/RaSla/sh/raw/main/cpu/set-cpufreq.sh
# chmod +x set-cpufreq.sh
```

* edit `set-cpufreq.sh` - see `Configure` section
* run commands as ROOT:

```shell
# nano /opt/set-cpufreq.sh
# ln -sf /opt/set-cpufreq.service /lib/systemd/system/
# systemctl daemon-reload
# systemctl start set-cpufreq
# systemctl enable set-cpufreq
# systemctl status set-cpufreq
# journalctl -u set-cpufreq
```

## Configure

* Get CPU info: max CPU-freq & governor, for example:

```shell
# cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors
performance powersave

# cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq
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

* Define vars in `set-cpufreq.sh`, for example:

```shell
CPU_GOVERNOR="powersave"
CPU_MAX_FREQ=2400000
```
