# Guide to Cross Compilation for a Raspberry Pi

1. **> [Start](readme.md)**
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
1. [ROS package development (RPi/XCS)](11-ros-dev.md)
1. [Compile and Install WiringPi](12-wiringpi.md)

# 1. Start

Welcome at this Cross Compilation Guide for a Raspberry Pi.

It started as a personal guide to keep track of how to setup a proper system, but grew to a public guide, where it hopefully can help many others too. This repository also holds toolchains and scripts to ease the cross-compilation as well as examples and tests to verify the setup.

The system is setup around a VirtualBox running an Ubuntu OS. This VirtualBox will hold all tools for the cross-compilation. A VirtualBox is chosen to ensure that we cannot mess up the main machine with faulty installations accidentally changing symbolic links (which happened to me on earlier journeys).

During this guide the following systems will be and cross-compiled (and some also native) and configured:
- [Userland](https://github.com/raspberrypi/userland)
- [OpenCV](http://opencv.org/) (with GTK and Python Bindings)
- [ROS](http://www.ros.org/) (with Python Bindings)
- [WiringPi](http://wiringpi.com)

Additionally we setup:
- headless Pi and headless VirtualBox (you do not need an additional monitor or keyboard for the pi!)
- DNS and folder sharing of the VirtualBox with the Host
- Wifi and SSH access on the raspberry Pi
- SSH over USB to connect to the Pi.
- Peripherals such as: i2c, RTC, IO expanders and the Pi camera
- Different ROS configurations
- and some more!

# How to Read?

The notes are in chronological order and can be followed with the table of contents on the top of the page.
As both the VirtualBox and Raspberry Pi will be configured to run headless (that is, without a display) instructions are command-line styled. Because we use 3 different systems, the commands are prefixed:

- `HOST~$` commands executed on the Host. (Developed on an OSX system, but probably works on Linux or Windows with MinGW or PuTTy too)
- `XCS~$` commands executed on the Cross-Compiler Server / VirtualBox. (Also called XCS)
- `RPI~$` commands executed on the Raspberry Pi. (Shortend as RPi)

In the github-repo 3 important folders can be found:

- "hello" - containing examples and test files:
  - pi: our "Hello World:" (testing cross-compile setup)
  - raspicam: a copy of the raspicam program from Userland (testing the cross-compiled Userland setup)
  - ocv: a tool to display an image (used to test the cross-compiled OpenCV infrastructure)
  - ros: "Hello World" for ros (testing the cross-compiled ROS setup)
  - WiringPi: blinking a led (testing the cross-compiling WiringPi libraries)
- "scripts" - containing several synchronisation tools
- "ros" - more complex tests for more complex ROS setups.

In the main directory you can also find the toolchain which will be used throughout this guide.

If you encounter problems or see mistakes, feel free to create an issue or merge request.

Enjoy!
Hessel.
