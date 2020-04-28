#!/bin/bash

# Default ssh-host?
host="$1"
if [ -z "$1" ]; then
  echo "Please provide target system to which you want to sync."
  echo " e.g: $0 rpizero-local-root"
  exit 0
fi

# sync
rsync -auHWv --no-perms --no-owner --no-group $XC_RPI_ROOTFS/ $host:/

# wait a bit so the RPi is able to update its internal file system with the updates
sleep 3

# Updates are pushed into a "cmd", which is send/executed to/on the RPi with ssh.
CMD=""
# Directory with faulty symlinks
TARGET_DIR="usr/lib/arm-linux-gnueabihf"
# Fetch corrected symlinks
RELINK=$(file $XC_RPI_ROOTFS/$TARGET_DIR/* | grep "symbolic link to $XC_RPI_ROOTFS" | awk '{print $1""$NF}' )
# Fix each symlink
for i in $RELINK ; do
  IFS=':' # split line by ':'
  # split entry in "src" and "dst" path
  read -a LN_SPLIT <<< "${i}"
  LN_SRC="${LN_SPLIT[0]}"
  LN_DST="${LN_SPLIT[1]}"
  # clear target root from "src" and "dst"
  LN_SRC=$(echo "${LN_SRC/#$XC_RPI_ROOTFS}" | sed "s/\/\//\//g")
  LN_DST=$(echo "${LN_DST/#$XC_RPI_ROOTFS}" | sed "s/\/\//\//g")
  echo "$LN_SRC >> $LN_DST"
  # update link
  CMD="$CMD ln -sf $LN_DST $LN_SRC;"
done
# fix links on rpi
ssh $host "$CMD"
