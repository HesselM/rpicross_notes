#!/bin/bash

ROOTFS="/home/pi/rpi/rootfs"
# Directory with faulty symlinks
TARGET_DIR="usr/lib/arm-linux-gnueabihf"

# Default ssh-host?
host="$1"
if [ -z "$1" ]; then
  host="rpizero-local-root"
fi

# sync
rsync -auHWv --no-perms --no-owner --no-group $ROOTFS $host:/

# Updates are pushed into a "cmd", which is send/executed to/on the RPi with ssh.
CMD=""
# Fetch corrected symlinks
RELINK=$(file $ROOTFS/$TARGET_DIR/* | grep "symbolic link to $TARGET_ROOT" | awk '{print $1""$5}' )
# Fix each symlink
for i in $RELINK ; do
  IFS=':' # split line by ':'
  # split entry in "src" and "dst" path
  read -a LN_SPLIT <<< "${i}"
  LN_SRC="${LN_SPLIT[0]}"
  LN_DST="${LN_SPLIT[1]}"
  # clear target root from "src" and "dst"
  LN_SRC="${LN_SRC/#$ROOTFS}"
  LN_DST="${LN_DST/#$ROOTFS}"
  echo "$LN_SRC >> $LN_DST"
  # update link
  CMD="$CMD ln -sf $LN_DST $LN_SRC;"
done

# fix links on rpi
ssh $host "$CMD"
