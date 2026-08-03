# Setup a Linux Target and install SiincosChargeEdge
Setup a Linux embedded PC as an edge device for SiincosChargeEdge. This guide covers Raspberry Pi or Raspberry Pi based devices, such as the reComputer R110x (from Seeed Studio).

This documentation is specifically tailored for the reComputer R1124-10, but can easily be adapted for other platforms. Only the sections explicitly marked under 'R1124-10 Specific' contain hardware-dependent details; all remaining instructions apply universally to other Raspberry Pi platforms.

## Minimum Hardware requirements
* Linux device with RS485 capability (USB-to-RS485 transceivers will work)
* Raspberry Pi 4 (or higher, I tested with a Compute Module 4, I assume RPi 3 will work, as well - I did not test it)

## Setup your Raspberry Pi (e.g. using Raspberry Pi Imager)
1. Flash your Raspberry Pi OS, recommended image: Raspberry Pi OS Lite, 64-bit
2. Set Hostname: `siincoschargeedge`
3. Set Username: `evchargermanager`
4. Set Password: `YourSuperSecretPassword`

(Or set according to your needs.)

## Set Network settings
Set network settings according to your needs, e.g.
* LAN DHCP client or static IP address
* WiFi SSID and Passphrase
* Make sure ssh access is enabled

## Set Basic Settings
1. Install Updates: `sudo apt-get update && sudo apt-get upgrade`
2. Enable password for root user: `sudo su root`. Type in `passwd` and enter the new password for root when prompted. Exit `root` (type: `exit`)
3. Add current user to *dialout*, *gpio* groups to allow access to serial ports and GPIOs: `sudo adduser $USER dialout`, `sudo adduser $USER gpio`
4. Check if user was added to group: `groups $USER` (list now should include `dialout` and `gpio`)
5. Add a daily auto-reboot at 3:00 – as a cronjob – to improve system stability for always-on systems. Cronjob will be run as root user: `sudo crontab -e`, then add `0 3 * * * /usr/bin/systemctl reboot`
6. Add your public ssh key for comfortable remote login: `ssh-copy-id -i ~/.ssh/id_rsa.pub evchargermanager@siincoschargeedge`

## Raspi Config
Run `sudo raspi-config` to perform the following tasks.
* (8) Update this tool
* (6) Advance Options --> (A1) Expand filesystem (reboot **immediately** after the process has finished)
* (5) Localization Options --> (L1) Locale: `en_GB.UTF-8` should be set as default locale for system environment (system-wide not user-wide)
* (5) Localization Options --> (L2) Timezone: should be set to your local timezone
* (3) Interface Options --> (I6) Disable *login shell via serial* to enable *serial interface*
* Reboot when finished

## R1124-10 Specific: Install Linux Device Tree Overlay for reComputer and enable internal RS485 transceivers
0. Make sure `git` is installed, install via: `sudo apt update && sudo apt install git`
1. Clone repo: `git clone --depth 1 https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git && cd seeed-linux-dtoverlays`
2. Install for e.g. reComputer R110x series: `sudo ./scripts/reTerminal.sh --device reComputer-R110x`
3. Reboot: `sudo reboot`
4. Open the firmware config: `sudo nano /boot/firmware/config.txt` and make sure the following configuration parameters are set as shown below. Reboot afterwards.
```env
enable_uart=1
dtoverlay=dwc2,dr_mode=host
dtoverlay=vc4-kms-v3d
dtoverlay=reComputer-R100x,uart2
```

## Build and install
Proceed with the <doc:Build-Install> section. Once complete, return here to continue configuring the edge device.

## Post configuration steps
The post configuration steps are not needed but I recommend them to enhance system stability.

### Configure OverlayFS (Readonly filesystem)
Configuring an overlay filesystem sets the `/` mount point to read-only, which means that all data that is written is persistent between reboots. This drastically reduces physical storage wearout when using an SD card or eMMC flash device. Run `sudo raspi-config` to perform the following tasks:
* TODO

### Backup & Restore using dd
Backup is compressed/decompressed in a single command using *gzip* together with *dd* for comfort reasons.

* Backup: `sudo dd if=/dev/rdiskX bs=1M status=progress | gzip > backup_image_name.gz`
* Restore: `gzip -dc backup_image_name.gz | sudo dd of=/dev/rdiskX bs=1M status=progress`

Make sure to use the *correct* device (`/dev/rdiskX`), otherwise you could destroy your whole system and/or other attached storage devices.
