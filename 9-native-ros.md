Source: http://wiki.ros.org/kinetic/Installation/Ubuntu

```
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
sudo apt-get update
sudo apt-get install ros-kinetic-desktop








1. install dependencies
    ```
    XCS~$ python-defusedxml python-netifaces python-nose libboost-all-dev libpoco-dev libeigen3-dev qtbase5-dev
    ```

1. install gtest
    ```
    XCS~$ sudo apt-get install libgtest-dev
    XCS~$ mkdir -p ~/build/gtest
    XCS~$ cd ~/build/gtest
    XCS~$ cmake /usr/src/gtest
    XCS~$ make
    XCS~$ sudo mv *.a /usr/lib
    ```

1. Download and install console_bridge
    ```
    XCS~$ mkdir -p ~/src
    XCS~$ cd ~/src
    XCS~$ git clone git://github.com/ros/console_bridge.git
    XCS~$ mkdir -p ~/build/console_bridge
    XCS~$ cd ~/build/console_bridge
    XCS~$ cmake ~/src/console_bridge
    XCS~$ make
    XCS~$ sudo make install
    ```

1. create catkin workspace
    ```
    XCS~$ mkdir -p ~/ros/catkin_native
    XCS~$ mkdir -p ~/ros/catkin_cross
    ```

    > TODO: update xc-ros with improved cross-workspace location

1. Download and install FULL ros
    ```
    XCS~$ rosinstall_generator desktop_full --rosdistro kinetic --deps --wet-only --tar > kinetic-desktop-full-wet.rosinstall
    XCS~$ wstool init -j8 src kinetic-desktop-full-wet.rosinstall
    XCS~$ ./src/catkin/bin/catkin_make_isolated \
        -DCMAKE_BUILD_TYPE=Release
    ```

1. 

