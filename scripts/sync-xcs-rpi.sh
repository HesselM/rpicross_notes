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
rsync -auHWv --no-perms --no-owner --no-group $ROOTFS/ $host:/

# wait a bit so the RPi is able to update its internal file system with the updates
sleep 3

# Updates are pushed into a "cmd", which is send/executed to/on the RPi with ssh.
CMD=""
# Fetch corrected symlinks
RELINK=$(file $ROOTFS/$TARGET_DIR/* | grep "symbolic link to $ROOTFS" | awk '{print $1""$NF}' )
# Fix each symlink
for i in $RELINK ; do
  IFS=':' # split line by ':'
  # split entry in "src" and "dst" path
  read -a LN_SPLIT <<< "${i}"
  LN_SRC="${LN_SPLIT[0]}"
  LN_DST="${LN_SPLIT[1]}"
  # clear target root from "src" and "dst"
  LN_SRC=$(echo "${LN_SRC/#$ROOTFS}" | sed "s/\/\//\//g")
  LN_DST=$(echo "${LN_DST/#$ROOTFS}" | sed "s/\/\//\//g")
  echo "$LN_SRC >> $LN_DST"
  # update link
  CMD="$CMD ln -sf $LN_DST $LN_SRC;"
done
# fix links on rpi
ssh $host "$CMD"
