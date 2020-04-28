#!/bin/bash

# Default ssh-host?
host="$1"
if [ -z "$1" ]; then
  echo "Please provide target system to which you want to sync."
  echo " e.g: $0 rpizero-local-root"
  exit 0
fi

# sync
rsync -auHWv $host:{/usr,/lib} $XC_RPI_ROOTFS

# wait a bit so the VM is able to update its internal file system with the updates
sleep 3

# Updates are pushed into a "cmd", which is eventually evaluated/executed
CMD=""
# Directory with faulty symlinks
TARGET_DIR="usr/lib/arm-linux-gnueabihf"
# Fetch broken symlinks
RELINK=$(file $XC_RPI_ROOTFS/$TARGET_DIR/* | grep "broken symbolic" | awk '{print $1""$NF}' )
# Fix each symlink
for i in $RELINK ; do
  IFS=':' # split line by ':'
  # split entry in "src" en "dst" path
  read -a LN_SPLIT <<< "${i}"
  LN_SRC="${LN_SPLIT[0]}"
  LN_DST="${LN_SPLIT[1]}"
  # add target root to "dst" and clear double slashes
  LN_DST=$(echo "$XC_RPI_ROOTFS/$LN_DST" | sed "s/\/\//\//g")
  echo "$LN_SRC >> $LN_DST"
  # update link
  CMD="$CMD ln -sf $LN_DST $LN_SRC;"
done

# fix links in vm
eval $CMD
