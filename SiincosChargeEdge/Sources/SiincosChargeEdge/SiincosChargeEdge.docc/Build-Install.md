# Build and Install SiincosChargeEdge
* TODO

## Install Binary
* TODO

## Build from source
### Install Swift
* Follow the steps on: [https://www.swift.org/install/linux/](https://www.swift.org/install/linux/)
* When installing Swift on Raspberry Pi OS based on Debian 13 (trixie), the installer may warn you that no direct matching toolchain version could be found and that you should chose the closesd matching distro. I selected `Debian 12` and it seems to work.

### Prepare the Swift Toolchain
The project currently requires Swift 6.3 to build
1. Install Swift 6.3 toolchain: `swiftly install 6.3`
2. Activate toolchain: `swiftly use 6.3`
3. Double check: `swift --version`

### Prepare the Project
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
9. Run as debug (to check everything works): TODO
9. Build a standalone binary: TODO
