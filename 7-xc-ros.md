# Crosscompiling : ROS

Before continuing, please make sure you followed the steps in:
- [Setup](1-setup.md)
- [Network/SSH](2-network.md)
- [crosscompile environment](4-xc-setup.md)

In this document the steps for crosscompiling ROS are described.

## Required Packages

As ROS has its own package-management system and eco system, multiple dependencies need to be installed on both the RPi and the VM. The VM requires foremost Python packages to process ROS dependencies, whereas the RPi requires additional information-processing libraries.

1. Install packages
    ```
    XCS~$ sudo apt-get install python-rosdep python-rosinstall-generator python-wstool python-rosinstall python-empy
  XCS~$ ssh rpizero-local
  RPI~$ sudo apt-get install pkg-config python2.7 python-dev sbcl libboost1.55 python-empy python-nose libtinyxml-dev libgtest-dev liblz4-dev libbz2-dev
    ```
    
1. Sync packages/headers from RPi to the VM-`rootfs`
    1. Clone repository (if not yet done)
        ```
        XCS~$ mkdir -p ~/rpi/build
        XCS~$ cd ~/rpi/build
        XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
        ```
    
    1. Allow script to be executed (if not yet done)
        ```
        XCS~$ chmod +x ~/rpi/build/rpicross_notes/sync-rpi-vm.sh
        ```

    1. Sync RPi with VM-`rootfs`
        ```
        XCS~$ /home/pi/rpi/build/rpicross_notes/sync-rpi-vm.sh
        ```

## Compilation

As mentioned before, the usage of `rsync` results in broken symlinks. Hence we need to restore the ones required for `ROS`:

1. Restore symlinks after syncing
    ```
    XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/librt.so.1 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
    XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/libbz2.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libbz2.so
    XCS~$ ln -sf /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so
    ```
    
    > When using the `sync`-scripts (provided in this repo) are used, this step can be omitted.
    
1. Download (if not yet done) our generic toolchain for compiling ROS. 
    ```
    XCS~$ mkdir -p ~/rpi/build
    XCS~$ cd ~/rpi/build
    XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
    ```

1. `ROS` uses `gtest` for several tests. The downloaded packages `libgtest-dev` only installs the source for `gtest`, therefore we need to compile it for ourselfs to generate the libraries. 
    ```
    XCS~$ mkdir -p ~/rpi/build/gtest
    XCS~$ cd ~/rpi/build/gtest
    XCS~$ cmake \
       -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
       /home/pi/rpi/rootfs/usr/src/gtest
    XCS~$ make
    XCS~$ mv *.a /home/pi/rpi/rootfs/usr/lib
    ```
    > SOURCE: https://www.eriksmistad.no/getting-started-with-google-test-on-ubuntu/
    > There is not `make install` so the generated libraries need to be copied manually to the appropriate folder.
    
1. We also need an utility called `console_bridge`, which is also compiled and installed from source.
    ```
    XCS~$ cd ~/rpi/src
    XCS~$ git clone https://github.com/ros/console_bridge
    XCS~$ mkdir -p ~/rpi/build/console_bridge
    XCS~$ cd ~/rpi/build/console_bridge
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
    /home/pi/rpi/src/console_bridge
    XCS~$ make
    XCS~$ make install DESTDIR=/home/pi/rpi/rootfs
    ```
    
1. After installing all dependencies, init `rosdep`.
    ```
    XCS~$ sudo rosdep init
    XCS~$ rosdep update
    ```

1. Create `catkin` workspace for the RPi-builds
    ```
    XCS~$ mkdir -p ~/rpi/ros_catkin_ws
    XCS~$ cd ~/rpi/ros_catkin_ws
    ```

1. Download `ROS` core packages and init workspace
    ```
    XCS~$ rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall
    XCS~$ wstool init -j8 src kinetic-ros_comm-wet.rosinstall
    ```
    
1. Build and install `ROS`
    ```
    XCS~$ mkdir -p build
    XCS~$ cd build
    XCS~$ ./src/catkin/bin/catkin_make_isolated \
        --install \
        --install-space /home/pi/rpi/opt/ros/kinetic \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
    ```
 
## Synchronisation

Todo..

## Testing

Todo..
