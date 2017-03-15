# ROS

Source: http://answers.ros.org/question/191070/compile-roscore-for-arm-board/

Original Guide: http://wiki.ros.org/kinetic/Installation/Source

## Compilation

 - rsync does not maintain symlinks, hence we need to correct some
 
 ```
 XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/librt.so.1 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/librt.so
 XCS~$ ln -sf /home/pi/rpi/rootfs/lib/arm-linux-gnueabihf/libbz2.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libbz2.so
 XCS~$ ln -sf /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so.1.0 /home/pi/rpi/rootfs/usr/lib/arm-linux-gnueabihf/libpython2.7.so
 ```
- Download our generic toolchain 

  ```
  XCS~$ mkdir -p ~/rpi/build
  XCS~$ cd ~/rpi/build
  XCS~$ git clone https://github.com/HesselM/rpicross_notes.git --depth=1
  
- GTEST: SOURCE: https://www.eriksmistad.no/getting-started-with-google-test-on-ubuntu/

```
XCS~$ mkdir -p ~/rpi/build/gtest
XCS~$ cd ~/rpi/build/gtest
XCS~$ cmake \
 -D CMAKE_TOOLCHAIN_FILE=/home/pi/rpi/build/rpicross_notes/rpi-generic-toolchain.cmake \
 /home/pi/rpi/rootfs/usr/src/gtest
XCS~$ make
XCS~$ mv *.a /home/pi/rpi/rootfs/usr/lib
```
- CONSOLE_BRIDGE: SOURCE: http://answers.ros.org/question/62215/where-to-install-console_bridge/

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
 
 - init rosdep
```
XCS~$ sudo rosdep init
XCS~$ rosdep update
```

- create catkin workspace
```
XCS~$ mkdir -p ~/rpi/ros_catkin_ws
XCS~$ cd ~/rpi/ros_catkin_ws
```

- get core packages and init workspace
```
XCS~$ rosinstall_generator ros_comm --rosdistro kinetic --deps --wet-only --tar > kinetic-ros_comm-wet.rosinstall
XCS~$ wstool init -j8 src kinetic-ros_comm-wet.rosinstall
```

- build ros
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

## Testing
