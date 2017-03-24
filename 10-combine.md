# Combining it all together.

ROS Setup:
- ROS master in VM (`roscore`)
- ROS node in VM
- [headless] ROS node on RPi

Process
- `roscore` is started
- ROS node in VM is started
- ROS node in VM sends master-host to RPi
- ROS node in VM starts (headless) ROS node on RPi
- ROS node in VM captures key
    - Message is send to RPi
    - RPi captures image
    - RPi sends back image
    - ROS node in VM displays image with OpenCV.
- ROS node in VM shutsdown
    - ROS node in VM terminates ROS node on RPi
    
## Setup

Several steps are required to create a functional setup
- Allow RPi to connect to a remote `roscore`
   
### Remote `ROS_MASTER_URI` : Setup

ROS nodes connect to a master (`roscore`) via a tcp-connection. This allows a ROS system to have external nodes, such as the RPi in our setup. The network adapter of the VM is configured to be attached to the NAT, therefore we cannot address it directly from the RPi. However, when using port forwarding, the RPi can connect to the Host, which forwards the request to the VM: 

- Machine > Settings > Network > Advanced > Port Forwarding > New Rule       
    - Name: ROS_MASTER
    - Protocol: TCP
    - Host IP: (leave empty)
    - Host Port: 11311
    - Guest IP: (leave empty)
    - Guest Port: 11311
    
### Remote `ROS_MASTER_URI` : Test

1. Compile for VM
    ```
    XCS~$ source ~/rpicross_notes/scripts/ros-native
    XCS~$ mkdir -p ~/build/ros/pub_local
    XCS~$ cd ~/build/ros/pub_local
    XCS~$ cmake ~/rpicross_notes/ros/pub_local
    XCS~$ make
    ```

1. Compile for RPi
    ```
    XCS~$ source ~/rpicross_notes/scripts/ros-cross
    XCS~$ mkdir -p ~/rpi/build/ros/pub_local
    XCS~$ cd ~/rpi/build/ros/pub_local
    XCS~$ cmake \
        -DCMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
        ~/rpicross_notes/ros/pub_local
    XCS~$ make
    XCS~$ scp devel/lib/local_chatter/publisher rpizero-local:~/
    ```

1. Open three terminals in the VM:
    1. Compile test code & start ros
        ```
        XCS~$ source ~/rpicross_notes/scripts/ros-native
        XCS~$ source ~/build/ros/pub_local/devel/setup.bash
        XCS~$ roscore
        ```
    1. After starting ros, start subscriber
        ```
        XCS~$ source ~/rpicross_notes/scripts/ros-native
        XCS~$ source ~/build/ros/pub_local/devel/setup.bash
        XCS~$ rosrun local_chatter subscriber
        ```
    1.  Start publisher on rpi       
        ```
        XCS~$ ssh rpizero-local
        RPI~$ export ROS_MASTER_URI=http://<HOSTIP>:11311
        RPI~$ source ~/source ros/src_cross/devel_isolated/setup.bash
        RPI~$ ./publisher
        ```
1. When succesfull, you should see:
    1. Publisher (RPi):
        ```
        RPI~$ ./publisher 
          [ INFO] [1490361500.794854734]: hello world 0
          [ INFO] [1490361500.894476970]: hello world 1
          [ INFO] [1490361500.994248202]: hello world 2
          [ INFO] [1490361501.094246431]: hello world 3
          [ INFO] [1490361501.194246659]: hello world 4
          [ INFO] [1490361501.294338885]: hello world 5
          [ INFO] [1490361501.394404112]: hello world 6
          [ INFO] [1490361501.494347342]: hello world 7
          [ INFO] [1490361501.594348570]: hello world 8
          ...
        ```
    1. Subscriber (VM):
        ```
        XCS~$ rosrun local_chatter subscriber
          [ INFO] [1490361501.387607575]: I heard: [hello world 5]
          [ INFO] [1490361501.486619994]: I heard: [hello world 6]
          [ INFO] [1490361501.588621491]: I heard: [hello world 7]
          [ INFO] [1490361501.688693481]: I heard: [hello world 8]
          ...
        ```
     > Note that some packages are lost?
