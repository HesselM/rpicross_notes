# Guide to Cross Compilation for a Raspberry Pi

1. [Start](readme.md)
1. [Setup XCS and RPi](01-setup.md)
1. **> [Setup RPi Network and SSH](02-network.md)**
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

# 3. Setup RPi Network and SSH

On this page we configure the network settings of the RPi and setup the required SSH connectivity. When completed you should be able to access the RPi from the XCS with the use of SSH keys via either WiFi and/or USB.

## Table of Contents

1. [Prerequisites](#prerequisites)
1. [Setup Wifi](#setup-wifi)
1. [Setup SSH](#setup-ssh)
1. [Setup Hostname](#setup-hostname)
1. [First Boot](#first-boot)
1. [SSH from XCS: pi](#ssh-from-xcs-pi)
1. [SSH from XCS: root](#ssh-from-xcs-root)
1. [SSH from XCS: usb](#ssh-from-xcs-usb)
1. [Next](#next)

## Prerequisites
- Setup of XCS and RPi

## Setup Wifi and SSH

1. If not connected, connect SDCard to the XCS.
1. Detect SDCard & find largest partition (the RPi filesystem)

    ```
    XCS~$ lsblk
      NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
      sda                           8:0    0   25G  0 disk
      ├─sda1                        8:1    0  487M  0 part /boot
      ├─sda2                        8:2    0    1K  0 part
      └─sda5                        8:5    0 24.5G  0 part
        ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
        └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
      sdb                           8:16   1  7.3G  0 disk
      ├─sdb1                        8:17   1   63M  0 part       <=== Smallest partition (boot)
      └─sdb2                        8:18   1  7.3G  0 part       <=== Largest partition
      sr0                          11:0    1 55.7M  0 rom  
    ```

1. Mount SDCard

    ```
    XCS~$ sudo mount /dev/sdb2 $XC_RPI_MNT
    ```

1. If required, configure the ip-address handling on the RPi. For example, you can use a static ip-address (e.g. `192.168.1.100`) as a fallback when DHCP fails:

    ```
    XCS~$ sudo nano $XC_RPI_MNT/etc/dhcpcd.conf
    ```

    Edit following lines as required for your setup and add these to the bottom of `dhcpcd.conf`:

    ```
    profile static_ip
    static ip_address=192.168.1.100/24
    static routers=192.168.1.1
    static domain_name_servers=192.168.1.1

    interface wlan0
    fallback static_ip
    ```

    > More information on how to manage (multiple) (static) networks be found [here](https://www.raspberrypi.org/forums/viewtopic.php?t=140252).

1. Setup WiFi credentials

    ```
    XCS~$ sudo nano $XC_RPI_MNT/etc/wpa_supplicant/wpa_supplicant.conf
    ```

    Add the required credentials. The order equals the connection order. So in this example, `network1` is first tried for setting up a connection, when failing, `network2` is tested.

    ```
    network={
      ssid="<network1>"
      psk="<password_of_network1>"
    }

    network={
      ssid="<network2>"
      psk="<password_of_network2>"
    }
    ```

## Setup SSH

1. To setup SSH we need access to the boot (or smallest) partition on the SDCard. As such, we first need to unmount the large partition and connect the smallest.

    ```
    XCS~$ sudo umount $XC_RPI_MNT
    XCS~$ sudo mount /dev/sdb1 $XC_RPI_MNT
    ```

1. Add ssh file and we are done.

    ```
    XCS~$ sudo touch $XC_RPI_MNT/ssh
    XCS~$ sudo umount $XC_RPI_MNT
    ```

## Setup Hostname

By default, the hostname of a RPi is `raspberrypi`, hence the RPi can be accessed via the dns `raspberrypi.local`. As multiple RPi's might be active in the environment, connection issues may occur. The following steps show how to change the hostname.

1. Mount the largest partition of the SDCard in the XCS.

    ```
    XCS~$ sudo mount /dev/sdb2 $XC_RPI_MNT
    ```

1. Edit `hostname`

    ```
    XCS~$ sudo nano $XC_RPI_MNT/etc/hostname
    ```

1. Change `raspberrypi` in e.g. `rpizw`
1. Edit `hosts`

    ```
    XCS~$ sudo nano $XC_RPI_MNT/etc/hosts
    ```

1. Change `127.0.0.1 raspberrypi` in e.g. `127.0.0.1 rpizw`.
    > The hostname in `etc/hosts` should equal the name written down in `etc/hostname` previously. The result might look like:

    ```
    127.0.0.1       localhost
    ::1             localhost ip6-localhost ip6-loopback
    ff02::1         ip6-allnodes
    ff02::2         ip6-allrouters

    127.0.0.1       rpizw
    ```

1. Finish setup by unmounting the mounted partition

    ```
    XCS~$ sudo umount $XC_RPI_MNT
    ```

## First Boot

Hooray! We can now finally boot the RPi. But before we can continue our quest to cross-compiling, we need to do some RPi-maintenance.

1. Insert the SDCard in the RPi and power it up.
1. SSH to the RPi (use hostname or ip-address if known)

    ```
    XCS~$ ssh pi@rpizw.local
    ```

1. Expand filesystem to use full size of SDCard & reboot

    ```
    RPI~$ sudo raspi-config --expand-rootfs
    RPI~$ sudo reboot now
    ```

1. After reboot, connect again & update RPi

    ```
    XCS~$ ssh pi@rpizw.local
    RPI~$ sudo apt-get update
    RPI~$ sudo apt-get dist-upgrade
    ```

## SSH from XCS: pi

Currently, you need to enter your password each time you connect to the RPi. With the use of SSH-keys, we can automate this process.

1. Generate ssh-keys in the XCS.

    ```
    XCS~$ cd ~/.ssh
    XCS~$ ssh-keygen -t rsa
      Generating public/private rsa key pair.
      Enter file in which to save the key (/home/pi/.ssh/id_rsa): rpizero_rsa
      Enter passphrase (empty for no passphrase): <empty>
      Enter same passphrase again: <empty>
      Your identification has been saved in rpizero_rsa.
      Your public key has been saved in rpizero_rsa.pub.
      ...
    ```

    > Optionally you can choose a different rsa-name (required if you are planning to use multiple keys for different systems) and set a passphrase (increasing security). In my setup I left the passphrase empty (just hitting enter).

1. Set correct permissions of the key-set

    ```
    XCS~$ chmod 700 rpizero_rsa rpizero_rsa.pub
    ```

1. Send a copy of the public key to the RPi so the RPi can verify the automated connection upon request.

    ```
    XCS~$ cat ~/.ssh/rpizero_rsa.pub | ssh pi@rpizw.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```

1. Setup ssh connection in `ssh_config` so we can login by only using a reference

    ```
    XCS~$ sudo nano /etc/ssh/ssh_config
    ```

    Depending on the configuration of `dhcpcd.conf` on the RPi, add the following lines:

    ```
    #connect via static ip
    Host rpizero
      HostName 192.168.1.100
      IdentityFile ~/.ssh/rpizero_rsa
      User pi
      Port 22

    # connect via hostname
    Host rpizero-local
      HostName rpizw.local
      IdentityFile ~/.ssh/rpizero_rsa
      User pi
      Port 22
    ```

    > You can edit the `Host XX` lines to any reference you seem fit. This reference is only used in the SSH call `ssh XX` to login to the defined setup.

1. Allow bash to invoke the configuration upon a ssh-call

    ```
    XCS~$ ssh-agent bash
    XCS~$ ssh-add /home/pi/.ssh/rpizero_rsa
    Identity added: /home/pi/.ssh/rpizero_rsa (/home/pi/.ssh/rpizero_rsa)
    ```

1. Test connection:

    ```
    XCS~$ ssh rpizero-local
    ```

    You should now be logged in onto the RPi via SSH, without entering your password.

## SSH from XCS: root

For synchronisation with our cross-compile environment the setup required root access over SSH.

1. Login to the RPi the enable root.

    ```
    XCS~$ ssh rpizero-local
    ```

1. Setup root-password.   

    ```
    RPI~$ sudo passwd root
    New password:
    Retype new password:
    passwd: password updated successfully
    ```

    > IMPORTANT: the given password should equal the password for the user `pi` !!

1. Enable root-login

    ```
    RPI~$ sudo nano /etc/ssh/sshd_config
    ```

    set `PermitRootLogin XXXX` to `PermitRootLogin yes`.

1. Restart ssh service and quit connection

    ```
    RPI~$ sudo service ssh restart
    RPI~$ exit
    ```

1. Configure ssh connection in `ssh_config`

    ```
    XCS~$ sudo nano /etc/ssh/ssh_config
    ```

    Depending on the configuration of `dhcpcd.conf` on the RPi, add the following lines:

    ```
    #connect via static ip
    Host rpizero-root
      HostName 192.168.1.100
      IdentityFile ~/.ssh/rpizero_rsa
      User root
      Port 22

    # connect via hostname
    Host rpizero-local-root
      HostName rpizw.local
      IdentityFile ~/.ssh/rpizero_rsa
      User root
      Port 22
    ```
    > You can edit the `Host XX` lines to any reference you seem fit. This reference is only used in the SSH call `ssh XX` to login to the defined setup.

1. Send a copy of the ssh-keys for the root user to the RPi:

    ```
    XCS~$ cat ~/.ssh/rpizero_rsa.pub | ssh root@rpizw.local "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
    ```

1. Test connection:

    ```
    XCS~$ ssh rpizero-local-root
    ```

    You should now be logged in onto the RPi via ssh as `root` without entering your password.

## SSH from XCS: USB

If your RPi will always be accessed via WiFi, this step can be skipped. If not: in this step we enable SSH access over the USB connector, to ensure we can connect to the RPi in environments without network connectivity.

1. If the RPi is running, shutdown, remove SDCard, connect the SDCard to the XCS and mount the smallest partition.

    ```
    $RPI~$ sudo shutdown now
    ```

    ```
    XCS~$ lsblk
      NAME                        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
      sda                           8:0    0   25G  0 disk
      ├─sda1                        8:1    0  487M  0 part /boot
      ├─sda2                        8:2    0    1K  0 part
      └─sda5                        8:5    0 24.5G  0 part
        ├─XCS--rpizero--vg-root   252:0    0 20.5G  0 lvm  /
        └─XCS--rpizero--vg-swap_1 252:1    0    4G  0 lvm  [SWAP]
      sdb                           8:16   1  7.3G  0 disk
      ├─sdb1                        8:17   1   63M  0 part       <=== Smallest partition
      └─sdb2                        8:18   1  7.3G  0 part
      sr0                          11:0    1 55.7M  0 rom   

    XCS~$ sudo mount /dev/sdb1 $XC_RPI_MNT
    ```

1. Update the configuration file

    ```
    XCS~$ sudo nano $XC_RPI_MNT/config.txt
    ```

    Add the following lines at the bottom of the file:

    ```
    #allow ssh over usb
    dtoverlay=dwc2
    ```

1. Update `cmdline.txt`

    ```
    XCS~$ sudo nano $XC_RPI_MNT/cmdline.txt
    ```

    Add `modules-load=dwc2,g_ether` right after `rootwait`. Because this file is very sensitive to enter, space or tabs, make sure you do not add additional characters to it. After editing the final file might look like:

    ```
    dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_ether
    ```

1. Mount largest partition

    ```
    XCS~$ sudo umount $XC_RPI_MNT
    XCS~$ sudo mount /dev/sdb2 $XC_RPI_MNT
    ```

1. Setup static fallback when DHCP is not providing an IP.

    ```
    XCS~$ sudo nano $XC_RPI_MNT/etc/dhcpcd.conf
    ```

    Add the following lines to `dhcpcd.conf`:

    ```
    interface usb0
    fallback static_ip
    ```

    > Note that this example is using the static profile, configured earlier in this guide. You could setup a different IP address as shown before. If you copied the settings from this guide, `dhcpcd.conf` should read:
    ```
    profile static_ip
    static ip_address=192.168.1.100/24
    static routers=192.168.1.1
    static domain_name_servers=192.168.1.1

    interface wlan0
    fallback static_ip

    interface usb0
    fallback static_ip
    ```

1. Unmount SDCard

    ```
    XCS~$ sudo umount $XC_RPI_MNT
    ```

1. Bootup the RPi with one end of the USB cable connected to your machine and the other end to the USB port of the device. Make sure that in case of the Raspberry Pi Zero you do not connect the USB cable with with the PWR port as this port does not support the USB protocol.

1. As we do not have DHCP server running, configure a static connection on the `HOST~$` (OSX):
    - System Preference > Network > RNDIS/Ethernet Gadget
    - Configure IPv4: Manually
        - IP Address: 192.168.1.1
        - Subnet Mask: 255.255.255.0
        - Router: 192.168.1.1

1. You should now be able to connect with the RPi via the set IP address, hostname or SSH-config

   ```
   XCS~$ ssh pi@192.168.1.100
   XCS~$ ssh rpizw.local
   XCS~$ ssh rpizero-local
   ```

1. A dump of `ifconfig` on the RPi might look like:
   ```
   RPI~$ ifconfig
   lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

   usb0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.100  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fe80::66a1:27c3:5dc2:b760  prefixlen 64  scopeid 0x20<link>
        ether 4a:3a:94:3c:c8:e5  txqueuelen 1000  (Ethernet)
        RX packets 420  bytes 76163 (74.3 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 174  bytes 17378 (16.9 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

   wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.2.181  netmask 255.255.255.0  broadcast 192.168.2.255
        inet6 fe80::95d0:e9ed:d380:bb04  prefixlen 64  scopeid 0x20<link>
        ether b8:27:eb:68:cc:d8  txqueuelen 1000  (Ethernet)
        RX packets 1151  bytes 195875 (191.2 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 353  bytes 52663 (51.4 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
   ```
   > Note that in this example `wlan0` is configured by DHCP, whereas `usb0` has been initialised with the static setup.

## Next

You can either [setup some peripherals such as i2c devices or the camera](03-peripherals.md) or start to [setup the cross-compilation environment](04-xc-setup.md).
