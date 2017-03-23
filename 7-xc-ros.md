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
    
    > The call to `sudo apt-get install` on the RPi might take a while as approximately 250Mb extracted and installed.
    > Installing `rospkg` and `catkin_pkg` may produce several errors when building `yaml` support while finishing gracefully. My guess is that all might be fine, but perhaps some future tests might show some issues. 
    
1. Sync [RPi libs to VM](4-xc-setup.md#from-rpi-to-vm)
    ```
    XCS~$ ~/rpicross_notes/scripts/sync-rpi-vm.sh
    ```
    
## Compilation

As mentioned before, the use of `rsync` results in broken symlinks. Hence we need to restore the ones required for `ROS`:

1. Restore symlinks after syncing

    > When using the [`sync`-scripts](scripts), this step can be omitted.

    ```
    XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/librt.so.1 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
    XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/libbz2.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libbz2.so
    XCS~$ ln -sf /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so
    ```
    
1. `ROS` uses `gtest` for several tests. The `apt-get` call for `libgtest-dev` only installs the source for `gtest`, therefore we need to crosscompile it for ourselfs to generate the libraries, using [rpi-generic-toolchain](rpi-generic-toolchain.cmake).
    ```
    XCS~$ mkdir -p ~/rpi/build/gtest
    XCS~$ cd ~/rpi/build/gtest
    XCS~$ cmake \
       -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
       /home/pi/rpi/rootfs/usr/src/gtest
    XCS~$ make
    XCS~$ mv *.a /home/pi/rpi/rootfs/usr/lib
    ```
    > SOURCE: https://www.eriksmistad.no/getting-started-with-google-test-on-ubuntu/
    > There is not `make install` so the generated libraries need to be copied manually to the appropriate folder.
    
1. We also need an utility called `console_bridge`, which we compile and install from source too. Again we use [rpi-generic-toolchain](rpi-generic-toolchain.cmake).
    ```
    XCS~$ cd ~/rpi/src
    XCS~$ git clone https://github.com/ros/console_bridge
    XCS~$ mkdir -p ~/rpi/build/console_bridge
    XCS~$ cd ~/rpi/build/console_bridge
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
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
    > Note that this workspace is not located in the `~/rpi` or `~/rpi/rootfs` directories. Because ROS comes with its own environment management system, a seperate directory is created which is synced with the RPi in a similar way as `rootfs`. Most important is that the path of the workspace in the VM equals (`/home/pi/ros/rpi_cross`) the path to which the workspace is synchronised on the RPi (which will be `/home/pi/ros/rpi_cross`).
    
    ```
    XCS~$ mkdir -p ~/ros/rpi_cross
    XCS~$ cd ~/ros/rpi_cross
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
        -DCMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake
    ```
    > This creates two folders: `devel_isolated` and `build_isolated` of which the latter can be ignored.

## Synchronisation

In addition to updates of `rootfs` we also need to synchronise `rpi_cross`.

Starting with `rootfs`:

1. Use a direct call:
    ```
    XCS~$ sudo rsync -auHWv --no-perms --no-owner --no-group /home/pi/rpi/rootfs/ rpizero-local-root:/
    ```
1. Or use the [link-correcting script](4-xc-setup.md#init-repository):
    ```
    XCS~$ /home/pi/rpicross_notes/scripts/sync-vm-rpi.sh
    ```

And for `~/ros/rpi_cross`:

1. Use a direct call:
    ```
    XCS~$ rsync -auHWv --no-perms --no-owner --no-group /home/pi/ros/rpi_cross/devel_isolated rpizero-local:/home/pi/ros/rpi_cross/
    XCS~$ rsync -auHWv --no-perms --no-owner --no-group /home/pi/ros/rpi_cross/src rpizero-local:/home/pi/ros/rpi_cross/
    ```
    > Which copies both `devel_isolated` and `src` from `/home/pi/ros/rpi_cross/*` (VM) to `/home/pi/ros/rpi_cross/*` (RPi)

1. Or use this script:
    ```
    XCS~$ /home/pi/rpicross_notes/scripts/sync-ros.sh
    ```

1. Unfortunatly ROS includes the path to `rootfs` and subsequent libraries in its binairies. To enable ROS on the RPi to find the proper libraries, a symbolic link is created, simulating the path to `rootfs`
    ```
    XCS~$ ssh rpizero-local
    RPI~$ mkdir -p /home/pi/rpi
    RPI~$ ln -s / /home/pi/rpi/rootfs
    ```
    
## Testing

Testing the compiled `ROS`-libraries and `catkin` workspace

Prerequisites: 
- Toolchain [installed](4-xc-setup.md#required-packages)
- ROS [compiled](#compilation) & [synced](#synchronisation)

Steps:

1. Set bash to use the crosscompile-ros settings
    ```
    XCS~$ ~/rpi/build/rpicross_notes/scripts/ros_cross.sh 
    ```
    
    > ROS biniaries such as `catkin_make` are actually python scripts. Therefore we can use several libraires/scripts from the crosscompiled workspace on both the RPi and VM.

1. Crosscompile the `helloros` code with the toolchain in this repositiory. 
    ```
    XCS~$ mkdir -p ~/rpi/build/hello/ros
    XCS~$ cd ~/rpi/build/hello/ros
    XCS~$ cmake \
        -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
        ~/rpicross_notes/hello/ros/
    XCS~$ make
    ```
    > Note that the toolchain invokes `XXXConfig.cmake` of the `catkin` in which ROS is build (`/home/pi/ros/rpi_cross`). 
    
1. Transfer `helloros` to the RPi (located in `devel/lib/helloros`)
    ```
    XCS~$ scp devel/lib/helloros/helloros rpizero-local:~/
    ```
    
1. Connect two terminals with the RPi
   1. Launch `roscore` in the first
       ```
       XCS~$ ssh rpizero-local
       RPI~$ source ~/ros/rpi_cross/devel_isolated/setup.bash 
       RPI~$ roscore
         ... logging to /home/pi/.ros/log/9d57fc26-0efa-11e7-97cb-b827eb418803/roslaunch-rpizw-hessel.local-893.log
         Checking log directory for disk usage. This may take awhile.
         Press Ctrl-C to interrupt
         Done checking log file disk usage. Usage is <1GB.

         started roslaunch server http://rpizw-hessel.local:42774/
         ros_comm version 1.12.7


         SUMMARY
         ========

         PARAMETERS
          * /rosdistro: kinetic
          * /rosversion: 1.12.7

         NODES

         auto-starting new master
         process[master]: started with pid [911]
         ROS_MASTER_URI=http://rpizw-hessel.local:11311/

         setting /run_id to 9d57fc26-0efa-11e7-97cb-b827eb418803
         process[rosout-1]: started with pid [924]
         started core service [/rosout]
       ```
       
   1. Launch `helloros` in the second
       ```
       XCS~$ ssh rpizero-local
       RPI~$ source ~/ros/rpi_cross/devel_isolated/setup.bash 
       RPI~$ ./helloros 
         [ INFO] [1490185604.127013218]: hello world 0
         [ INFO] [1490185604.226970277]: hello world 1
         [ INFO] [1490185604.326862336]: hello world 2
         [ INFO] [1490185604.426858394]: hello world 3
         ...
       ```
       
> Code for this test is partially taken from http://wiki.ros.org/ROS/Tutorials/WritingPublisherSubscriber(c%2B%2B)

