# Setup a Linux Target and install SiincosChargeEdge
Setup a Linux embedded PC as an edge device for SiincosChargeEdge. This guide covers Raspberry Pi or Raspberry Pi based devices, such as the reComputer R110x (from Seeed Studio).

This documentation is specifically tailored for the reComputer R1124-10, but can easily be adapted for other platforms. Only the sections explicitly marked under 'R1124-10 Specific' contain hardware-dependent details; all remaining instructions apply universally to other Raspberry Pi platforms.

## Flash Raspberry Pi OS (using Raspberry Pi Imager)
1. Use: Raspberry Pi OS Lite, 64-bit
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
4. Open the firmware config: `sudo nano /boot/firmware/config.txt` and make sure the following configuration parameters are set correspondingly.
```env
enable_uart=1
dtoverlay=dwc2,dr_mode=host
dtoverlay=vc4-kms-v3d
dtoverlay=reComputer-R100x,uart2
```
5. Reboot: `sudo reboot`

## Install and configure SiincosChargeEdge
* TODO

### Install Binary
* TODO

### Build from source
#### Install Swift
* Follow the steps on: [https://www.swift.org/install/linux/](https://www.swift.org/install/linux/)
* When installing Swift on Raspberry Pi OS based on Debian 13 (trixie), the installer may warn you that no direct matching toolchain version could be found and that you should chose the closesd matching distro. I selected `Debian 12` and it seems to work.

#### Prepare the Swift Toolchain
The project currently requires Swift 6.3 to build
1. Install Swift 6.3 toolchain: `swiftly install 6.3`
2. Activate toolchain: `swiftly use 6.3`
3. Double check: `swift --version`

#### Prepare the Project
On the target (Raspberry, reComputer, etc.), run the following steps:
1. Make sure the path `/opt/SiincosChargeEdge` exists:
 * Create folder `sudo mkdir -p /opt/SiincosChargeEdge`
 * Change ownership to common user: `sudo chown evchargermanager:evchargermanager /opt/SiincosChargeEdge`
 * This is the install location (and is currently fixed)
2. Create the following directory layout:
 * `mkdir -p /opt/SiincosChargeEdge/Assets`
 * `mkdir -p /opt/SiincosChargeEdge/Logs`
3. Clone repo (e.g. into your home folder) and walk to the swift package folder: `git clone https://github.com/JoooHannesk/SiincosCharge.git && cd SiincosCharge/SiincosChargeEdge/`
4. Run `swift build` to check if everything builds correctly
5. Copy and rename the config file to the install location `cp Assets/config.json.sample /opt/SiincosChargeEdge/Assets/config.json`
6. Now run `swift test` to check if all tests pass.
7. Edit the config file in place: TODO
8. Add the MQTT (ThingsBoard) certificate: TODO
9. Build a standalone binary: 

## Configure OverlayFS (Readonly filesystem)
Run `sudo raspi-config` to perform the following tasks.
* TODO

## Backup & Restore using dd
Backup is compressed/decompressed in a single command using *gzip* together with *dd* for comfort reasons.

* Backup: `sudo dd if=/dev/rdiskX bs=1M status=progress | gzip > backup_image_name.gz`
* Restore: `gzip -dc backup_image_name.gz | sudo dd of=/dev/rdiskX bs=1M status=progress`

Make sure to use the *correct* device (`/dev/rdiskX`), otherwise you could destroy your whole system and/or other attached storage devices.
