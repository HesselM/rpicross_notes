#!/bin/sh

# sync 
rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/

# fix links
TARGET_ROOT=""

CMD=""
CMD="$CMD ln -sf $TARGET_ROOT/lib/arm-linux-gnueabihf/librt.so.1 $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/librt.so;"
CMD="$CMD ln -sf $TARGET_ROOT/lib/arm-linux-gnueabihf/libbz2.so.1.0 $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/libbz2.so;"
CMD="$CMD ln -sf $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 $TARGET_ROOT/usr/lib/arm-linux-gnueabihf/libpython2.7.so;"

# fix links on rpi
ssh rpizero-local-root "$CMD"
