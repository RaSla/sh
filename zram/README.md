# ZRAM (memdisk for caches)

Script for ZRAM cache-dirs (and SWAP, optional)

## Install

* Copy 2 zram-files to the `/opt` folder
* edit `zram.service` file - change Username in `ExecStart=` string (last argument, `linux` by default)
* run commands as ROOT:
```shell
# cd /opt
# ln -sf /opt/zram.service /lib/systemd/system/
# systemctl daemon-reload
# systemctl start zram
# systemctl enable zram
# systemctl status zram
```
