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

This repository started as a personal guide to keep track of how to setup a proper system, but grew to a public guide, where it hopefully can help many others too. It also contains toolchains and scripts to ease the cross-compilation process as well as examples and tests to verify the setup.

The system is build around a VirtualBox running an Ubuntu OS. This VirtualBox will hold all tools for the cross-compilation. A VirtualBox is chosen to ensure that we cannot mess up the main machine with faulty installations or accidentally changing system-critical symbolic links (which happened to me on earlier journeys).

During this guide the following systems will be configured, (cross)compiled and installed:
- [Userland](https://github.com/raspberrypi/userland)
- [OpenCV](http://opencv.org/) (with GTK and Python Bindings)
- [ROS](http://www.ros.org/) (with Python Bindings)
- [WiringPi](http://wiringpi.com)

Additionally we setup:
- headless VirtualBox, locally accessible via SSH.
- headless Pi (you do not need an additional monitor or keyboard for the pi!).
- DNS and folder sharing of the VirtualBox with the Host.
- Wifi and SSH access on the Raspberry Pi.
- SSH over USB to connect to the Pi when there is no WiFi.
- Peripherals such as: i2c, RTC, IO expanders and the Pi Camera.
- Different ROS configurations.
- and more!

To use this guide, experience with VirtualBox, C, Python and the terminal/nano are assumed. You also need a Raspberry Pi and SD-card reader (as we'll initially configure the Pi via de SDCard, connected to the VirtualBox).

# How to Read?

The notes are in chronological order and can be followed with the table of contents on the [top of the page](#guide-to-cross-compilation-for-a-raspberry-pi).
As both the VirtualBox and Raspberry Pi will be configured to run headless (that is, without a display) instructions are command-line styled. These instructions are prefixed with identifiers, as we use 3 different systems (Host, XCS and RPI):

- `HOST~$` commands executed on the Host. (This guide is developed on an OSX system, but probably works on Linux or Windows with MinGW or PuTTy too).
- `XCS~$` commands executed on the Cross-Compilation Server / VirtualBox. (Also called XCS)
- `RPI~$` commands executed on the Raspberry Pi. (Shortened as RPi)

In the [github-repo](https://github.com/HesselM/rpicross_notes) three important folders can be found:

- "hello" - containing examples and test files:
  - pi: to test the cross-compile setup.
      >  Hello World!
  - raspicam: to test the cross-compiled Userland setup.
      > Snapping a picture with the PiCamera with a self-compiled version of "raspivid"
  - ocv: to test the cross-compiled OpenCV infrastructure.
      > Displaying a picture via the OpenCV calls `imread` and `imshow`.
  - ros: to test the cross-compiled ROS setup.
      > Running `roscore` and `roscomm `on the Pi, printing "Hello World"
  - WiringPi: to test the cross-compiled WiringPi setup.
      > Blinking a Led.
- "scripts" - containing several synchronisation tools
- "ros" - more complex tests for more complex ROS setups.

In the main directory you can also find the toolchain which will be used throughout this guide.

If you encounter problems or see mistakes, feel free to create an [issue](https://github.com/HesselM/rpicross_notes/issues/new) or [pull request](https://github.com/HesselM/rpicross_notes/compare).

Enjoy!
Hessel.

PS. This guide is also available at https://hesselm.github.io/rpicross_notes/.

PPS. Special thanks to: [RaymondKirk](https://github.com/RaymondKirk), [ConnorChristie](https://github.com/ConnorChristie), [Skammi](https://github.com/Skammi), [compyl118](https://github.com/compyl118) for suggestions, fixes, testing and helping out.
