# Guide to Setup and Cross Compile for a Raspberry Pi

This repository is a personal guide to setup a cross compilation environment to compile OpenCV and ROS programs for a Raspberry Pi. It contains details on how to setup a VirtualBox, configure SSH / X-server / network settings, how to sync syncing / back up files to the Raspberry Pi and of course how to compile and install OpenCV and ROS. Experience with VirtualBox, C, Python and the terminal/nano are assumed. Usage of external keyboards or monitors for the Raspberry Pi is not required: setup is done via card mounting or SSH. 

At the end of this list you should have:
- A Virtualbox (VM) running Ubuntu Server 16.04 LTS, with:
  - SSH connectivity from HOST to GUEST and from GUEST to the Raspberry Pi
  - Crosscompilation environment including:
    - Toolchain /  compilers to compile for the Raspberry Pi (zero)
    - Userland libraries (GPU support for the Raspberry Pi)
    - OpenCV 3.2 with additional modules, library support such as GTK+ and Python bindings
    - ROS-comm with Python bindings
    - Synchronisation tools to update the Raspberry Pi with the (cross) compiled libraries.
  - Native environment supporting:
    - ROS with Python bindings
    - OpenCV 3.2 with Python bindings
- A Raspberry Pi (zero) (RPi) running Jessie Lite, including
  - OpenCV with Python Bindings
  - ROS-comm with Python Bindings
  - Running PiCamera
  - i2c and a Real Time Clock (RTC)
- A VM able to run `roscore` to which the Raspberry Pi (RPi) can connect as a node. 

Before the required steps are explained, some disclaimers:

1. Many, many, many StackOverflow questions, Github issues, form-posts and blog-pages have helped me developing these notes. Unfortunatly I haven't written down all these links and hence cannot thank or link all authors, for which my apology. Here is an incomplete list of used sources:
  - VirtualBox SSH: https://forums.virtualbox.org/viewtopic.php?f=8&t=55766
  - SSH X-server: http://unix.stackexchange.com/questions/12755/how-to-forward-x-over-ssh-from-ubuntu-machine
  - RPI: https://www.raspberrypi.org/documentation/installation/installing-images/linux.md
  - RPI RTC: https://learn.adafruit.com/adafruits-raspberry-pi-lesson-4-gpio-setup/configuring-i2c
  - RPI RTC: https://thepihut.com/collections/raspberry-pi-hats/products/rtc-pizero
  - PkgConfig: http://dev.gentoo.org/~mgorny/pkg-config-spec.html
  - PkgConfig: https://autotools.io/pkgconfig/cross-compiling.html
  - OpenCV: http://docs.opencv.org/2.4/doc/tutorials/introduction/linux_gcc_cmake/linux_gcc_cmake.html
  - OpenCV/RPI: http://docs.opencv.org/2.4/doc/tutorials/introduction/crosscompilation/arm_crosscompile_with_cmake.html
  - OpenCV/Raspicam: https://thinkrpi.wordpress.com/2013/05/22/opencvpi-cam-step-2-compilation/
  - OpenCV/AR: http://answers.opencv.org/question/90298/static-lib-cross-compile-zlib-error/
  - OpenCV/Python: http://thebbbdiary.blogspot.nl/2015_01_01_archive.html
  - Shared Libraries: http://redmine.webtoolkit.eu/projects/wt/wiki/Cross_compile_Wt_on_Raspberry_Pi/
  - ROS: http://answers.ros.org/question/191070/compile-roscore-for-arm-board/
  - ROS: http://wiki.ros.org/kinetic/Installation/Source
  - gtest: https://www.eriksmistad.no/getting-started-with-google-test-on-ubuntu/
1. There is no guarantee that the steps described in these notes are the best available. As I'm not an expert, better solutions might be out there. The provided steps however resulted in a working/workable setup for me.
1. If you happen to know a better (and working) solution, have a question, suggestion or if you spot a mistake: feel free to post an issue!

# How to Read?

The notes are more or less in chronological order, hence start from top the bottom. Commands are prefixed with the system on which the commands needs to be run:

- `HOST~$` commands executed on the Host. As this guide is developed using OSX, commands will be unix-styled.
- `XCS~$` commands executed on the Cross-Compiler Server / Virtualbox
- `RPI~$` commands executed on the Raspberry Pi

# Index

Information:
1. [Setup VM and RPi](01-setup.md)
1. [Setup Network/SSH](02-network.md)
1. [Setup RPi Peripherals](03-xc-peripherals.md)
1. [Setup Crosscompile environment](04-xc-setup.md)
1. [Crosscompile and Install Userland](05-xc-userland.md)
1. [Crosscompile and Install OpenCV](06-xc-opencv.md)
1. [Crosscompile and Install ROS](07-xc-ros.md)
1. [Compile and Install OpenCV](08-native-opencv.md)
1. [Compile and Install ROS](09-native-ros.md)
1. [Remote ROS (RPi node and VM master)](10-ros-remote.md)

Test-code:
- Setup: [hello/pi](hello/pi)
- Userland: [hello/raspicam](hello/raspicam)
- OpenCV: [hello/ocv](hello/ocv)
- ROS: [hello/ros](hello/ros)

ROS publish-subscriber (for remote operation)
- [chatter](ros/chatter)

Tools:
- Generic Toolchain: [rpi-generic-toolchain.cmake](rpi-generic-toolchain.cmake)
- Sync RPi to VM: [sync-rpi-vm.sh](scripts/sync-rpi-vm.sh) (see: [setup](04-xc-setup.md))
- Sync VM to RPi: [sync-vm-rpi.sh](scripts/sync-vm-rpi.sh) (see: [setup](04-xc-setup.md))
- Sync ROS to RPi: [sync-ros.sh](scripts/sync-ros.sh) (see: [xc-ros](07-xc-ros.md#synchronisation) and [ros remote](10-ros-remote))

ROS (compile) environment setters:
- Compile for RPi: [ros-cross](scripts/ros-cross) (see: [xc-ros](07-xc-ros.md) and [ros remote](10-ros-remote))
- Compile for VM: [ros-native](scripts/ros-native) (see: [ros](08-native-ros.md) and [ros remote](10-ros-remote))

Enjoy!
