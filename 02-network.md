# Network/SSH

As we have a functioning VM and as we have installed Raspbian on the SDCard, lets configure the network settings.

## RPi-Network Connection

1. If not connected, connect SDCard to the VM.
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
      ├─sdb1                        8:17   1   63M  0 part
      └─sdb2                        8:18   1  7.3G  0 part       <=== Largest partion
      sr0                          11:0    1 55.7M  0 rom  
    ```

1. Mount SDCard
    ```
    XCS~$ mkdir -p /home/pi/rpi/mnt
    XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt
    ```

1. If required, configure ipadress handling. For example, use a static ipaddress (`192.168.1.100`) as an fallback, when DHCP fails:
    ```
    XCS~$ sudo nano /home/pi/rpi/mnt/etc/dhcpcd.conf
    ```

    Edit and add the following lines to `dhcpcd.conf` as required for your setup:
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
    XCS~$ sudo nano /home/pi/rpi/mnt/etc/wpa_supplicant/wpa_supplicant.conf
    ```

    Add the required credentials. In this example, the order equals the connection order. So initially `network1` is tried for setting up a connection, after which, when failing/not available, `network2` is tested.
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

1. Finish setup by unmounting the mounted partition
    ```
    XCS~$ sudo umount /home/pi/rpi/mnt
    ```

## RPi Hostname

By default, the hostname of a RPi is `raspberrypi`, hence the RPi can be accessed via the dns `raspberrypi.local`. As multiple RPi's might be active in the environment, connection issues may occur. The following steps show how to change the hostname properly.

1. Mount largest partion of the SDCard in the VM. (if not yet mounted)
    ```
    XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt
    ```

1. Edit `hostname`
    ```
    XCS~$ sudo nano /home/pi/rpi/mnt/etc/hostname
    ```

1. Change `raspberrypi` in e.g. `rpizw`
1. Edit `hosts`
    ```
    XCS~$ sudo nano /home/pi/rpi/mnt/etc/hosts
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
    XCS~$ sudo umount /home/pi/rpi/mnt
    ```


## SSH Setup

### RPi: Enable SSH

1. If not connected, connect SDCard to the VM.
1. Detect SDCard & mount SMALLEST partition (the boot partition)
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

    XCS~$ sudo mount /dev/sdb1 /home/pi/rpi/mnt
    ```

1. Add ssh file
    ```
    XCS~$ sudo touch /home/pi/rpi/mnt/ssh
    ```

1. Finish setup by unmounting the mounted partition
    ```
    XCS~$ sudo umount /home/pi/rpi/mnt
    ```

### RPi: First Boot

Hooray! We can now finally boot the RPi. But before we can continue our quest to cross-compiling, we need to do some RPi-maintenance.

1. Insert the SDCard in the RPi and power it up.
1. SSH to the RPi (use hostname or ipadress if known)
    ```
    XCS~$ ssh pi@rpizw.local
    ```

1. Expand filesystem to use full size of SDCard & reboot
    ```
    RPI~$ sudo raspi-config --expand-rootfs
    RPI~$ sudo reboot now
    ```

1. After boot, connect again & update RPi
    ```
    XCS~$ ssh pi@rpizw.local
    RPI~$ sudo apt-get update
    RPI~$ sudo apt-get dist-upgrade
    ```

### SSH-Keys : pi-user

Currently, you need to type your password each time you connect with the RPi. With the use of ssh-keys, we can automate this process.

1. Generate ssh-keys in the VM.
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
    > Optionally you can choose a different rsa-name (required if you are planning to use multie keys for different systems) and set a passphrase (increasing security). In my setup I left the passphrase empty (just hitting enter).

1. Set correct permisions of the key-set
    ```
    XCS~$ chmod 700 rpizero_rsa rpizero_rsa.pub
    ```

1. Send a copy of the public key to the RPi so it can verify the connection  
    ```
    XCS~$ cat ~/.ssh/rpizero_rsa.pub | ssh pi@rpizw.local "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
    ```

1. Configure ssh connection in `ssh_config`
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

    You should now be logged in onto the RPi via ssh, without entering your password.

### SSH-Keys : root
For synchronisation of the RPi-rootfs in our crosscompile environment and the root of the 'real' RPi, ssh requires root acces.

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

1. Restart ssh service
    ```
    RPI~$ sudo service ssh restart
    ```

1. Exit connection
    ```
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

1. Send a copy of the ssh-keys for the root user to the RPi:
    ```
    XCS~$ cat ~/.ssh/rpizero_rsa.pub | ssh root@rpizw.local "mkdir -p ~/.ssh && cat >>  ~/.ssh/authorized_keys"
    ```

1. Test connection:
    ```
    XCS~$ ssh rpizero-local-root
    ```

    You should now be logged in onto the RPi via ssh as `root` without entering your password.

# Next

Next step: [activating/installing peripherals](03-peripherals.md) such as i2c, a Real Time Clock or the Camera.

Or, if you do not need those: [setup the crosscompilation environment](04-xc-setup.md).


# EXTRA: SSH over USB

When the RPi is used in an environment without network connectivity, enabling SSH over USB might be a solution.

1. If the RP=i is running, shutdown RPi and remove SDCard.
    ```
    $RPI~$ sudo shutdown now
    ```

1. Detect SDCard & mount SMALLEST partition (the boot partition)
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

    XCS~$ sudo mount /dev/sdb1 /home/pi/rpi/mnt
    ```

1. Update the configuration file
    ```
    XCS~$ sudo nano /home/pi/rpi/mnt/config.txt
    ```

    Add the following at the bottom of the file:
    ```
    #allow ssh over usb
    dtoverlay=dwc2
    ```

1. Update `cmdline.txt`
    ```
    XCS~$ sudo nano /home/pi/rpi/mnt/cmdline.txt
    ```

    Add `modules-load=dwc2,g_ether` right after `rootwait`. Because this file is very sensitive to enter, space or tabs, make sure you do not add additional characters to it. After editing the final file might look like:
    ```
    dwc_otg.lpm_enable=0 console=serial0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline fsck.repair=yes rootwait modules-load=dwc2,g_ether
    ```

1. Unmount SDCard / smallest partition
    ```
    XCS~$ sudo umount /home/pi/rpi/mnt
    ```

1. Mount largest partition
    ```
    XCS~$ sudo mount /dev/sdb2 /home/pi/rpi/mnt
    ```

1. Setup static fallback when DHCP is not providing an IP.
    ```
    XCS~$ sudo nano /home/pi/rpi/mnt/etc/dhcpcd.conf
    ```

    Add the following lines to `dhcpcd.conf`:
    ```
    interface usb0
    fallback static_ip
    ```

    > Note that this example is using the static profile, configured earlier in this guide. You could setup a different IP adress as shown before. If you copied the settings from this guide, `dhcpcd.conf` should read:
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
    XCS~$ sudo umount /home/pi/rpi/mnt
    ```

1. Bootup the RPi with the USB cable connected to your local machine and to the USB port of the device. Make sure that in case of the Raspberry Pi Zero you do not connect the USB cable with with the PWR port as this port does not support the USB protocol.

1. Setup connection details on the HOST~$ (OSX):
    - System Preference > Network > RNDIS/Ethernet Gadget
    - Configure IPv4: Manually
        - IP Address: 192.168.1.1
        - Subnet Mask: 255.255.255.0
        - Router: 192.168.1.1

1. You should now be able to connect with the RPi via the set IP address. A dump of `ifconfig` on the RPi might look like:
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
