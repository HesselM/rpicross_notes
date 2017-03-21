NOTE: THIS PAGE IS STILL UNDER CONSTRUCTION AS I DID NOT MANAGE YET TO CROSSCOMPILE ROS

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
    RPI~$ sudo apt-get install pkg-config python2.7 python-dev python-pip sbcl libboost-all-dev libtinyxml-dev libgtest-dev liblz4-dev libbz2-dev libyaml-dev python-nose python-empy python-netifaces python-defusedxml
    RPI~$ sudo pip install -U rospkg catkin_pkg
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

    > When using the `sync`-scripts (provided in this repo) are used, this step can be omitted.

    ```
    XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/librt.so.1 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
    XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/libbz2.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libbz2.so
    XCS~$ ln -sf /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so
    ```
      
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

1. Create `catkin` workspace for the RPi-builds.
    > Note that this workspace is not located in the `~/rpi` or `~/rpi/rootfs` directories. Because ROS comes with its own environment management system, a seperate directory is created which is synced with the RPi in a similar way as `rootfs`. Most important is that the path of the workspace in the VM equals (`/home/pi/ros_catkin_ws_cross`) the path to which the workspace is synchronised on the RPi (which will be `/home/pi/ros_catkin_ws_cross`).
    
    ```
    XCS~$ mkdir -p ~/ros_catkin_ws_cross
    XCS~$ cd ~/ros_catkin_ws_cross
    ```

1. Download `ROS` core packages and init workspace
    ```
    XCS~$ rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall
    XCS~$ wstool init -j8 src kinetic-ros_comm-wet.rosinstall
    ```
    
1. Build `ROS`
    ```
    XCS~$ ./src/catkin/bin/catkin_make_isolated \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake
    ```
    > This creates two folders: `devel_isolated` and `build_isolated` of which the latter can be ignored.

## Synchronisation

In addition to updates of `rootfs` we also need to synchronise `ros_catkin_ws_cross`.

Starting with `rootfs`:

1. Use a direct call:
    ```
    XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/
    ```
    
1. Or use the link-correcting script:
    1. Clone repository (if not yet done)
        ```
        XCS~$ mkdir -p ~/rpi/build
        XCS~$ cd ~/rpi/build
        XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
        ```
    
    1. Allow script to be executed (if not yet done)
        ```
        XCS~$ chmod +x ~/rpi/build/rpicross_notes/sync-vm-rpi.sh
        ```

    1. Sync VM-`rootfs` with RPi`
        ```
        XCS~$ /home/pi/rpi/build/rpicross_notes/sync-vm-rpi.sh
        ```
And for `ros_catkin_ws_cross`:

1. Use a direct call:
    ```
    XCS~$ rsync -auHWv --no-perms --no-owner --no-group /home/pi/ros_catkin_ws_cross/devel_isolated rpizero-local:/home/pi/ros_catkin_ws_cross/
    XCS~$ rsync -auHWv --no-perms --no-owner --no-group /home/pi/ros_catkin_ws_cross/src rpizero-local:/home/pi/ros_catkin_ws_cross/
    ```
    > Which copies both `devel_isolated` and `src` from `/home/pi/ros_catkin_ws_cross/*` (VM) to `/home/pi/ros_catkin_ws_cross/*` (RPi)



## Testing

Source: http://wiki.ros.org/ROS/Tutorials/WritingPublisherSubscriber(c%2B%2B)

```
XCS~$ ssh rpizero-local
# fix prefix..
RPI~$ sudo find /opt/ros/kinetic -type f -exec sed -i 's/\/home\/pi\/rpi\/rootfs\//\//g' {} +
RPI~$ sudo find /opt/ros/kinetic -type f -exec sed -i 's/\/home\/pi\/rpi\/ros_catkin_ws\//\/home\/pi\//g' {} +
RPI~$ source devel_isolated/setup.bash 
RPI~$ roscore
```

        
1. > The building process of `ROS` is includeing several times the full path of headers and libraries. As these are located at a different location on the RPi and VM, a correction is needed:
    ```
    XCS~$ ssh rpizero-local
    RPI~$ sudo find /opt/ros/kinetic -type f -exec sed -i 's/\/home\/pi\/rpi\/rootfs\//\//g' {} +
    RPI~$ sudo find /opt/ros/kinetic -type f -exec sed -i 's/\/home\/pi\/rpi\/ros_catkin_ws\//\/home\/pi\//g' {} +
    ```
    > NOTE/TODO: not all paths are corrected, several links to `/home/pi/rpi/tool` still exist. 
    > NOTE/TODO: investigate effect on syncing rpi-vm


```
XCS~$ ssh rpizero-local
RPI~$ source /opt/ros/kinetic/setup.bash
RPI~$ roscore
```
