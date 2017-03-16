#!/bin/sh

# sync 
rsync -auHWv rpizero-local-root:{/usr,/lib} ~/rpi/rootfs

# fix links
ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/librt.so.1 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/libbz2.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libbz2.so
ln -sf /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so
