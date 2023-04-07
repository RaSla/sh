#!/bin/bash
#
# Create ZRAM in /tmp/zram for Chrome/Chromium/Opera/FireFox	 CACHE

NAME="zram.sh"
VERSION=2

# ZSIZE_CACHE - (Mb) size for Cache-dir
ZSIZE_CACHE=512
# ZSIZE_SWAP - (Mb) size for SWAP; 0 = SWAP is OFF
ZSIZE_SWAP=512
#
ZPATH=/tmp/zram/
#
ZDEV_CACHE=zram0
ZDEV_SWAP=zram1

ZFLAG_CACHE=/var/run/zram.cache
ZFLAG_SWAP=/var/run/zram.swap
USER_NAME="linux"

function help_v {
  echo "VERSION: $NAME v$VERSION - tool for control ZRAM"
  echo "USAGE: $NAME <COMMAND> [<ARGUMENT-1> ... <ARGUMENT-LAST>]"
}

function help_date {
  echo "* date [<DATETIME>]  ==  Show DateTime (in log-format)"
  echo "   |- <DATETIME> - optional 'date -d' parameter:"
  echo "   ./$NAME date"
  echo "  2018-10-08 10:58:03 +0500"
  echo "   ./$NAME date '10 minute ago'"
  echo "  2018-10-08 10:48:03 +0500"
  echo "   ./$NAME date '1 day 1 hour ago'"
  echo "  2018-10-09 09:58:03 +0500"
  echo "   ./$NAME date 'next fri'"
  echo "  2018-10-12 00:00:00 +0500"
}

function help_start {
  echo "* (+) start [<ZSIZE_CACHE> <ZSIZE_SWAP> <USER_NAME>]  ==  Start ZRAM config"
  echo "   |- <ZSIZE_CACHE> - (Mb) size for Cache-dir. Default is '$ZSIZE_CACHE'"
  echo "   |- <ZSIZE_SWAP>  - (Mb) size for SWAP; 0 = SWAP is OFF. Default is '$ZSIZE_SWAP'"
  echo "   |- <USER_NAME>   - User-name for ownership of cache-dir. Default is '$USER_NAME'"
}

function help_stop {
  echo "* (-) stop ==  Stop ZRAM config"
  echo "   |- turning off ALL ZRAM-devices"
}

function help_all {
  help_v
  echo "COMMAND choose one of those:"
  help_start
  help_stop
  help_date
}

# Simple commands check
if [ -z "$1" ]; then
  help_all
  exit 1
elif [ "$1" = "--help" ]; then
  help_all
  exit 0
elif [ "$1" = "--version" ]; then
  help_v
  exit 0
fi

# Get current date & time
# cur_date=$(get_date)
# cur_date=$(get_date "10 minute ago")
function get_date {
  # '2018-10-08 10:49:28 +0500'
  DATE_FORMAT="+'%Y-%m-%d %H:%M:%S %z'"
  # ISO 8601
  # date +'%Y-%m-%dT%H:%M:%S%z'
  # '2018-10-08T10:49:28+0500'
  # date -u +'%Y-%m-%dT%H:%M:%SZ'
  # '2018-10-08T05:49:28Z'
  if [ -z "$1" ]; then
    cmd="date $DATE_FORMAT"
    eval ${cmd} ;
  else
    cmd="date -d '$@' $DATE_FORMAT"
    eval ${cmd} ;
  fi
}

# Start ZRAM devices
function zram_start {
    z_cache=$1
    z_swap=$2
    z_user=$3
    # Make ZRAM-devices
    echo "> Making ZRAM devices..."
    if [[ ${z_swap} -gt 0 ]]; then
      modprobe zram num_devices=2
      # make SWAP block-device
      echo $((z_swap*1024*1024)) > /sys/block/${ZDEV_SWAP}/disksize ;
    else
      modprobe zram num_devices=1 ;
    fi
    echo $((z_cache*1024*1024)) > /sys/block/${ZDEV_CACHE}/disksize
    ls -al /dev/zram*

    # Make swap (optional)
    if [[ ${z_swap} -gt 0 ]]; then
      echo "> Making SWAP in ZRAM-device1..."
      touch ${ZFLAG_SWAP}
      mkswap /dev/${ZDEV_SWAP} > /dev/null
      swapon /dev/${ZDEV_SWAP} -p 10
    fi

    # Make FS for Cache
    echo "> Making FS on ZRAM-device0 and mount it in ${ZPATH}..."
    mkfs -t ext4 /dev/${ZDEV_CACHE} > /dev/null
    mkdir -p ${ZPATH}
    mount /dev/${ZDEV_CACHE} ${ZPATH}
    touch ${ZFLAG_CACHE}

    # Make dirs
    echo "> Making DIRs for Web-Browser's Cache..."
    mkdir -p ${ZPATH}/cache/chromium
    mkdir -p ${ZPATH}/cache/google-chrome
    mkdir -p ${ZPATH}/cache/opera
    mkdir -p ${ZPATH}/cache/mozilla
    echo "chown Cache-dir for '${z_user}'"
    chown -R ${z_user} ${ZPATH}

    echo "> Making ZRAM completed !"
}

# Stop ZRAM devices
function zram_stop {
  # If SWAP is created by this script
  if [ -f ${ZFLAG_SWAP} ]; then
    echo "Turning off SWAP ..."
    swapoff /dev/${ZDEV_SWAP}
    rm ${ZFLAG_SWAP}
  fi

  if [ -f ${ZFLAG_CACHE} ]; then
    echo "Unmount ZRAM DIRs..."
    rm -rf ${ZPATH}/*
    umount ${ZPATH}

    echo "Resize ZRAM down to 0..."
    echo 1 > /sys/block/${ZDEV_SWAP}/reset
    echo 1 > /sys/block/${ZDEV_CACHE}/reset

    echo "Unloading module ZRAM..."
    modprobe -r zram
    rm ${ZFLAG_CACHE} ;
  fi
}

### ARGUMENTS PARSER ###
# var for General Command
gcmd="$1"
# Shift params for 1 step
shift
if [ "$gcmd" = "+" ]; then gcmd="start"
elif [ "$gcmd" = "-" ]; then gcmd="stop"
fi

case "$gcmd" in
  start )
    z_cache=$1
    z_swap=$2
    z_user=$3

    if [ -z "$1" ]; then z_cache=${ZSIZE_CACHE}; fi
    if [ -z "$2" ]; then z_swap=${ZSIZE_SWAP}; fi
    if [ -z "$3" ]; then z_user=${USER_NAME}; fi
    #echo "DEBUG {z_cache}=${z_cache} {z_swap}=${z_swap} {z_user}=${z_user}"
    zram_start ${z_cache} ${z_swap} ${z_user}
    ;;
  stop )
    zram_stop
    ;;
  date )
    get_date "$@"
    ;;
  *)
    help_all
    ;;
esac
