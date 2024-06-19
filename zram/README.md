# ZRAM (memdisk for caches)

Script for ZRAM cache-dirs (and SWAP, optional)

## Install

* Copy 2 zram-files to the `/opt` folder. Example:

```shell
# cd /opt
# wget https://github.com/RaSla/sh/raw/main/zram/zram.service
# wget https://github.com/RaSla/sh/raw/main/zram/zram.sh
# chmod +x zram.sh
```

* edit `zram.service` file - see `Configure` section
* (optional) edit `CACHE_FOLDERS` var in `zram.sh`
* run commands as ROOT:

```shell
# nano /opt/zram.service
# ln -sf /opt/zram.service /lib/systemd/system/
# systemctl daemon-reload
# systemctl start zram
# systemctl enable zram
# systemctl status zram
```

## Configure

`ExecStart=/opt/zram.sh + 500 0 linux`

Arguments:

* `+` - create zram device(s) ; `-` - destory zram device(s)
* `500` - size (Mb) for cache-dir `/tmp/zram`
* `0` - size (Mb) for SWAP device. If > 0, then SWAP-device will be created
* `linux` - Username for `chown` (`linux` by default; `<USERNAME>:<GROUP>` are acceptable too)

## Usage

By User: create sym-links to the ZRAM-folders, like:

```shell
$ cd ~/.cache
$ rm -rf mozilla
$ ln -s /tmp/zram/mozilla/
$ ln -s /tmp/zram/thorium/
$ ln -s /tmp/zram/yandex-browser/
```
