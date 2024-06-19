# ZRAM (memdisk for caches)

Script for ZRAM cache-dirs (and SWAP, optional)

## Install

* Copy 2 zram-files to the `/opt` folder
* edit `zram.service` file - see `Configure` section
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
* `linux` - Username for `chown` (last argument, `linux` by default)

## Usage

By User: create sym-links to the ZRAM-folders, like:

```shell
$ cd /.cache
$ rm -rf mozilla
$ ln -s /tmp/zram/cache/mozilla/
$ ln -s /tmp/zram/cache/thorium/
$ ln -s /tmp/zram/cache/yandex-browser/
```
