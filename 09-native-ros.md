# ROS

The key idea of this guide is to have a RPi running as a node in a ROS network. Of this network, the core shall be running in the VM, hence we also need to install ROS locally. Most of the steps of this guide are described at the [ROS wiki](http://wiki.ros.org/kinetic/Installation/Ubuntu)

## Required Packages

As ROS is installed via `apt-get`, no additional packages need to be installed.

## Compilation

1. Ensure the VM is able to connect with the ROS repository
    ```
    XCS~$ sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
    XCS~$ sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
    XCS~$ sudo apt-get update
    ```
    
1. Install ROS-Desktop (omitting similations etc.)
    ```
    XCS~$ sudo apt-get install ros-kinetic-desktop
    XCS~$ rosdep update
    ```
   
## Synchronisation

No synchronisation is required.

## Testing

Prerequisites: 
 - ROS [compiled](#compilation)
 - Repository [initialised](4-xc-setup.md#init-repository)

Steps:

1. Set bash to use the native-ros settings
    ```
    XCS~$ source ~/rpicross_notes/scripts/ros_native
    ```
    
1. Compile the `helloros` code *without* the toolchain. 
    ```
    XCS~$ mkdir -p ~/build/hello/ros
    XCS~$ cd ~/build/hello/ros
    XCS~$ cmake ~/rpicross_notes/hello/ros/
    XCS~$ make
    ```
1. Open a second terminal.
    1. Launch `roscore` in the first
        ```
        XCS~$ source ~/rpicross_notes/scripts/ros_native
        XCS~$ roscore
          ... logging to /home/pi/.ros/log/9c219342-0fc9-11e7-b1fd-08002741e196/roslaunch-XCS-rpizero-2600.log
          Checking log directory for disk usage. This may take awhile.
          Press Ctrl-C to interrupt
          Done checking log file disk usage. Usage is <1GB.

          started roslaunch server http://XCS-rpizero:45758/
          ros_comm version 1.12.7


          SUMMARY
          ========
          
          PARAMETERS
           * /rosdistro: kinetic
           * /rosversion: 1.12.7

          NODES

          auto-starting new master
          process[master]: started with pid [2611]
          ROS_MASTER_URI=http://XCS-rpizero:11311/

          setting /run_id to 9c219342-0fc9-11e7-b1fd-08002741e196
          process[rosout-1]: started with pid [2624]
          started core service [/rosout]
       ```
       
    1. Launch `helloros` in the second
        ```
        XCS~$ source ~/rpicross_notes/scripts/ros_native
        XCS~$ ~/build/hello/ros/devel/lib/helloros/helloros 
          [ INFO] [1490274566.925321564]: hello world 0
          [ INFO] [1490274567.026256196]: hello world 1
          [ INFO] [1490274567.125635032]: hello world 2
          [ INFO] [1490274567.225916579]: hello world 3
          [ INFO] [1490274567.325554161]: hello world 4
          ...
        ```
        
> Code for this test is partially taken from http://wiki.ros.org/ROS/Tutorials/WritingPublisherSubscriber(c%2B%2B)
