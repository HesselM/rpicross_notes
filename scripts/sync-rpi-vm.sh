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
rsync -auHWv $host:{/usr,/lib} $ROOTFS

CMD=""
# Fetch broken symlinks
RELINK=$(file $ROOTFS/$TARGET_DIR/* | grep "broken symbolic" | awk '{print $1""$6}' )
# Fix each symlink
for i in $RELINK ; do
  IFS=':' # split line by ':'
  # split entry in "src" en "dst" path
  read -a LN_SPLIT <<< "${i}"
  LN_SRC="${LN_SPLIT[0]}"
  LN_DST="${LN_SPLIT[1]}"
  # add target root to "dst"
  LN_DST="$ROOTFS$LN_DST"
  echo "$LN_SRC >> $LN_DST"
  # update link
  CMD="$CMD ln -sf $LN_DST $LN_SRC;"
done

# fix links in vm
eval $CMD
