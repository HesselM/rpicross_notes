# Guide to Setup and Cross Compile for a Raspberry Pi

This repository is a personal guide to setup a cross compilation environment to compile OpenCV and ROS programs for a Raspberry Pi. It contains details on how to setup a VirtualBox, configure SSH / X-server / network settings, how to sync syncing / back up files to the Raspberry Pi and of course how to compile and install OpenCV and ROS. Experience with VirtualBox, C, Python and the terminal/nano are assumed. Usage of external keyboards or monitors for the Raspberry Pi is not required: setup is done via card mounting or SSH. 

At the end of this list you should have:
- A Virtualbox running Ubuntu Server 16.04 LTS, with:
  - SSH connectivity from HOST to GUEST and from GUEST to the Raspberry Pi
  - Crosscompilation environment including:
    - Toolchain /  compilers to compile for the Raspberry Pi
    - Userland libraries (GPU support for the Raspberry Pi)
    - OpenCV with additional modules and library support such as GTK+
    - Synchronisation tools to update the Raspberry Pi with our compiled libraries.
  - ROS Master environment [TODO]
- A Raspberry Pi running Jessie Lite, including
  - X-Server
  - OpenCV with Python Bindings
  - Running PiCamera
  - i2c and a Real Time Clock (RTC)
  - ROS and autoset sccript to connect with an external ROS-Master. [TODO]

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
- [Setup VM and RPi](1-setup.md)
- [Setup Network/SSH](2-network.md)
- [Setup RPi Peripherals](3-xc-peripherals.md)
- [Setup Crosscompile environment](4-xc-setup.md)
- [Compile Userland](5-xc-userland.md)
- [Compile OpenCV](6-xc-opencv.md)
- [Compile ROS](7-xc-ros.md)

Test-code:
- Setup: [hello/pi](hello/pi)
- Userland: [hello/raspicam](hello/raspicam)
- OpenCV: [hello/ocv](hello/ocv)

Tools:
- Generic Toolchain: [rpi-generic-toolchain.cmake](rpi-generic-toolchain.cmake)
- Sync RPi to VM: [sync-rpi-vm.sh](sync-rpi-vm.sh) (see: [setup](4-xc-setup.md))
- Sync VM to RPi: [sync-vm-rpi.sh](sync-vm-rpi.sh) (see: [setup](4-xc-setup.md))


Enjoy!
