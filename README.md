# Guide to Setup and Cross Compile for a Raspberry Pi

This repository is a personal guide to setup a cross compilation environment to compile OpenCV and ROS programs on a Raspberry Pi. It contains details on the setup of a VirtualBox, SSH / X-server / network settings, syncing / backing up and of course how to compile and install OpenCV with Python bindings and dynamic library support (such as GTK). Experience with VirtualBox, C, Python and the terminal are assumed. Usage of external keyboards or monitors for the Raspberry Pi is not required: setup is done via card mounting or SSH. 

Disclaimer: Many, many, many StackOverflow, Github issues, form-posts and blog-pages have helped me developing these notes. Unfortunatly I haven't written down these links and hence cannot thank or link the original author, for which my apology. 

## How to Read?

The notes are more or less in chronological order, hence start from top the bottom. Commands are prefixed with the system on which the commands needs to be run:

- `HOST~$` commands executed on the Host. As this guide is developed using OSX, commands will be unix-styled.
- `XCS~$` commands executed on the Cross-Compiler Server / Virtualbox
- `RPI~$` commands executed on the Raspberry Pi


# Setup

In order to be able to experiment with compilation and installation of the necessary tools without messing op the main system, all tools will be installed in a clean and headless [VirtualBox](https://www.virtualbox.org/) environment. Development will be done on the host with VirtualBox accesing the code via shared folders.

## Virtualbox

### Installation
- Download VirtualBox
- Download Ubuntu 16.04 Server LTS [https://www.ubuntu.com/download/server]
- New VirtualBox Image:
	Name:	XCS-rpizero
	Type:	Linux
	Version:	Ubuntu (64-bit)
	Memory:	4096 MB
	+ Create a virtual hard disk now
	Size:		25,00 GB
	Type:	VMDK
	Storage:	Dynamically allocated	
- Virtualmachine changed settings:
	CPU:	3
	Network > Advanced > Port Forwarding > New Rule
		Name:		SSH
		Protocol: 		TCP
		Host IP:		<empty>
		Host Port:		2222
		Guest IP:		<empty>
		Guest Port:	22
	Storage > Controller IDE > Empty > IDE Secondary Master > Choose Virtual Optical Disk File >  ubuntu-16.04.2-server-amd64.iso
	Ports > USB > USB3 controller
- Use HOST-dns
HOST~$ VBoxManage modifyvm "XCS-rpizero" --natdnshostresolver1 on
- Start VM
	Hostname: XCS-server
	User: pi
	Password: raspberry
- Update VM
XCS~$ sudo apt-get update
XCS~$ sudo apt-get dist-upgrade
- Install ssh-server
XCS~$ sudo apt-get install openssh-server
- create directory structure
XCS~$ mkdir -p ~/rpi/rootfs ~/rpi/src ~/rpi/build ~/rpi/img ~/rpi/mnt


### Shared Folder



## Raspberry Pi

# Connection

## Network settings

## SSH

# Raspberry Pi Peripherals

## Real-time Clock
### Enable i2c
### Enable RTC

## Camera


# Crosscompilation

## Setup

## Userland

## OpenCV

# Testing
## Hello Pi!
## Hello Camera!
## Hello OpenCV!



