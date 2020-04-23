# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. [Setup RPi Network and SSH](02-network.md)
1. [Setup RPi Peripherals](03-peripherals.md)
1. [Setup Cross-compile environment](04-xc-setup.md)
1. [Cross-compile and Install Userland](05-xc-userland.md)
1. [Cross-compile and Install OpenCV](06-xc-opencv.md)
1. [Cross-compile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and XCS master)](10-ros-remote.md)
1. **> [ROS package development (RPi/XCS)](11-ros-dev.md)**
1. [Compile and Install WiringPi](12-wiringpi.md)

# 12. ROS package development (RPi/XCS)

TO BE UPDATED. GUIDE MIGHT STILL WORK.

The scripts to source the ROS-builds on both the RPi and VM expect paths in which a package is build.
Both [ros-native](scripts/ros-native) and [ros-cross](scripts/ros-cross) search for the `devel*` folders created bij the ROS builders.

For native building, packages need to be build in:
```
XCS~$ ~/build/ros/<packagename>
```

For cross compilation, packages need to be build in:
```
XCS~$ ~/ros/<packagename>_cross
```

After cross-compiling a package for the RPi, the `~/ros` directory needs to be synchronised with the RPi via:
```
XCS~$ ~/rpicross_notes/scripts/sync-ros.sh
```

The source of a package can be located everywhere.

# Prerequisites:

- VM and RPi Configured: [setup](01-setup.md) and [network](02-network.md)
- [Toolchain](04-xc-setup.md) installed
- [Repository](04-xc-setup.md#init-repository) downloaded
- ROS (cross)compiled: [cross](07-xc-ros.md) and [native](09-native-ros.md)

Optional:
- Userland (for gpu-support)
- OpenCV (cross)compiled: [cross](06-xc-opencv.md) and [native](08-native-opencv.md) (for vision-support)
- [Perhiperals](03-peripherals.md) (for camera/i2c)
- [ROS-port forwarding](10-ros-remote.md#host-vm-port-forwarding) (for mixed support)

# Native-compilation

1. Set correct paths for native compilation
    ```
    XCS~$ source ~/rpicross_notes/scripts/ros-native
    ```
1. Build package
    ```
    XCS~$ mkdir -p ~/build/ros/<packagename>
    XCS~$ cd ~/build/ros/<packagename>
    XCS~$ cmake <path>/<to>/<package>
    XCS~$ make
    ```
1. Update ROS-paths, so new package is included
    1. Via generic script:
        ```
        XCS~$ source ~/rpicross_notes/scripts/ros-native  <hostname> <rpiname>
        ```
        > `<hostname>` and `<rpiname> are optional and only needed when a RPi is used. See [Testing](10-ros-remote.md#testing).

    1. or, build package only:
        ```
        XCS~$ source ~/build/ros/<packagename>/devel/setup.bash
        ```
1. Assuming a `roscore` is running, the package can be started via `rosrun`:
    ```
    XCS~$ rosrun <packagename> <node>
    ```

# Cross-compilation

1. Set correct paths for cross compilation
    ```
    XCS~$ source ~/rpicross_notes/scripts/ros-cross
    ```
1. Build package
    ```
    XCS~$ mkdir -p ~/ros/<packagename>
    XCS~$ cd ~/ros/<packagename>
    XCS~$ cmake \
        -DCMAKE_TOOLCHAIN_FILE=/home/pi/rpicross_notes/rpi-generic-toolchain.cmake \
        <path>/<to>/<package>
    XCS~$ make
    ```
1. Update RPi
    ```
     XCS~$ ~/rpicross_notes/scripts/sync-ros.sh <rpi-host>
    ```
    > `<rpi-host>` is optional. When omitted, `rpizero-local` is used.

1. Assuming a `roscore` is running, the package can be started via `rosrun`:
    ```
    XCS~$ ssh rpizero-local
    RPi~$ rosrun <packagename> <node>
    ```

# Mixed

When a mixed setup is used, e.g. when both the VM and RPi need to be active,
the following command should be executed before logging-in to the RPi or starting a node on either the VM or RPi:
```
XCS~$ source ~/rpicross_notes/scripts/ros-native <hostname> <rpiname>
```
- `<hostname>`: hostname of device on which `roscore` runs.
    1. when VM: name of `HOST~$`
    1. when RPi: name of RPi
    > detect the hostname with the `hostname` command
- `<rpiname>`: name of ssh-connection defined in `ssh_config` of the RPi
