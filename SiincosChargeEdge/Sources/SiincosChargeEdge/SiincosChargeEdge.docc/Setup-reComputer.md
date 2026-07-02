# Setup reComputer as Edge Device for SiincosChargeEdge

This documentation is written for a reComputer R1124-10.

## Flash Raspberry Pi OS (using Raspberry Pi Imager)
1. Use: Raspberry Pi OS Lite, 64-bit
2. Set Hostname: `siincoschargeedge`
3. Set Username: `evchargermanager`
4. Set Password: `solut2026AdvProdCharge`

(Or set according to your needs.)

## Set Network settings
Set network settings according to your needs, e.g.
* LAN DHCP client or static IP address
* WiFi SSID and Passphrase
* Make sure ssh access is enabled

## Set Basic Settings
1. Install Updates: `sudo apt-get update && sudo apt-get upgrade`
2. Enable password for root user: `sudo su root`. Type in `passwd` and enter the new password for root when prompted.
3. Add current user to *dialout*, *gpio* groups to allow access to serial ports and GPIOs: `sudo adduser $USER dialout`, `sudo adduser $USER gpio`
4. Check if user was added to group: `groups $USER` (list now should include `dialout` and `gpio`)
5. Add a daily auto-reboot at 3:00 – as a cronjob – to improve system stability for always-on systems. Cronjob will be run as root user: `sudo crontab -e`, then add `0 3 * * * /usr/bin/systemctl reboot`
6. Add your public ssh key for comfortable remote login: `ssh-copy-id -i ~/.ssh/id_rsa.pub evchargermanager@siincoschargeedge`

## Raspi Config
Run `sudo raspi-config` to perform the following tasks.
* (8) Update this tool
* (6) Advance Options --> (A1) Expand filesystem (reboot **immediately** after the process has finished)
* (5) Localization Options --> (L1) Locale: `en_GB.UTF-8` should be set as default locale for system environment (system-wide not user-wide)
* (5) Localization Options --> (L2) Timezone: should be set to *Europe/Berlin*
* (3) Interface Options --> (I6) Disable *login shell via serial* to enable *serial interface*
* Reboot when finished

## Install Linux Device Tree Overlay for reComputer
1. Clone repo: `git clone --depth 1 https://github.com/Seeed-Studio/seeed-linux-dtoverlays.git && cd seeed-linux-dtoverlays`
2. Install for e.g. reComputer R110x series: `sudo ./scripts/reTerminal.sh --device reComputer-R110x`
3. Reboot: `sudo reboot`

## Configure OverlayFS (Readonly filesystem)
Run `sudo raspi-config` to perform the following tasks.
* TODO

## Install and configure SiincosChargeEdge Binary
* TODO

## Backup & Restore using dd
Backup is compressed/decompressed in a single command using *gzip* together with *dd* for comfort reasons.

* Backup: `sudo dd if=/dev/rdiskX bs=1M status=progress | gzip > backup_image_name.gz`
* Restore: `gzip -dc backup_image_name.gz | sudo dd of=/dev/rdiskX bs=1M status=progress`

Make sure to use the *correct* device (`/dev/rdiskX`), otherwise you could destroy your whole system and/or other attached storage devices.

## Development related

### Install Swift
* Follow the steps on: [https://www.swift.org/install/linux/](https://www.swift.org/install/linux/)
* When installing Swift on Raspberry Pi OS based on Debian 13 (trixie), the installer may warn you that no direct matching toolchain version could be found and that you should chose the closesd matching distro. I selected `Debian 12` and it seems to work.

### Prepare Project
* Place project in: 
