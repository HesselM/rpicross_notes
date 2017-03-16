#!/bin/sh

# sync 
rsync -auHWv rpizero-local-root:{/usr,/lib} ~/rpi/rootfs

# fix links
TARGET_ROOT="/home/pi/rpi/rootfs"

CMD=""
CMD="$CMD ln -sf $TARGET_ROOT/lib/arm-linux-gnueabihf/librt.so.1 $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/librt.so;"
CMD="$CMD ln -sf $TARGET_ROOT/lib/arm-linux-gnueabihf/libbz2.so.1.0 $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/libbz2.so;"
CMD="$CMD ln -sf $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/libpython2.7.so;"

# fix links in vm
eval $CMD
