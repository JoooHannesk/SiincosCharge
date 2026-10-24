# SiincosCharge

An open-source, privacy-first EV charging infrastructure management system designed for multi-location deployment and decentralized control. Take back your data and manage all your charging points across different locations through elegant dashboards – without being locked into proprietary cloud providers or restrictive corporate ecosystems.

![SiincosCharge Web showing a charging point while a vehicle is plugged in and charging: about 7 kW power and 4.42 kWh energy consumed so far.](https://github.com/JoooHannesk/SiincosCharge/blob/main/SiincosChargeEdge/Sources/SiincosChargeEdge/SiincosChargeEdge.docc/SiincosChargeWebUIChargingFullscreen.png)

| ![Charts dashboard with total power, per-phase power and per-phase current over time.](https://github.com/JoooHannesk/SiincosCharge/blob/main/SiincosChargeEdge/Sources/SiincosChargeEdge/SiincosChargeEdge.docc/SiincosChargeWebUIChartsFullscreen.png) | ![Table of charging sessions with timestamp, session ID, charging time, energy consumed and current setpoint.](https://github.com/JoooHannesk/SiincosCharge/blob/main/SiincosChargeEdge/Sources/SiincosChargeEdge/SiincosChargeEdge.docc/SiincosChargeWebUIChargingSessionLogs.png) |
|:---:|:---:|
| *Charts: total power, per-phase power and current* | *Charging session history* |

## The Vision
Many modern EV charging solutions rely on proprietary cloud backends that limit data ownership, customization and integration possibilities.

**SiincosCharge bridges this gap.** It is a production-ready, cloud-enabled open-source project that runs on lightweight edge devices (like a Raspberry Pi), offering multi-site management and data sovereignty. By utilizing **ThingsBoard CE** as its decentralized backend foundation, SiincosCharge delivers an enterprise-grade IoT architecture directly into your hands – without corporate vendor lock-in.

---

## Core Features

### 🏢 1. Multi-Location Management
Manage multiple charging points across various physical locations (e.g., your home, your office, your business location, your vacation rental) in a single unified interface. Monitor real-time power consumption, set load limits, and aggregate historical charging data effortlessly.

### 👥 2. Charger Sharing
Want to share your charger with friends, neighbors or employees? Authorize users directly within your ThingsBoard CE tenant.

### 📊 3. Reporting
SiincosCharge tracks precise energy consumption and automatically records every charging session as a structured, machine-readable session report (JSON), ready for dashboards, scripts, or custom integrations.

### 🛡️ 4. Data Sovereignty (Private Cloud)
Your charging data belongs to you. SiincosCharge is natively cloud-enabled but designed to run on *your* infrastructure. By hosting your own open-source backend based on ThingsBoard CE, you get full remote access and a seamless user experience – without sharing telemetry or user data with third-party vendors.

### ⚡️ 5. Dynamic Load Balancing
Automatic load balancing in case multiple EV chargers are operating concurrently. The system dynamically adjusts the charging current per station to ensure the overall electrical installation limit is never exceeded.

### 📄 6. Grid Compliance through Operator Curtailment (Ready for §14a EnWG)
Designed with German grid regulations in mind. The system is designed to interface with a grid operator receiver / ripple control receiver (e.g., via a dry-contact / potential-free input on the edge hardware) to temporarily pause or dim charging sessions down to the legally mandated minimum (e.g., 4.2 kW). Two digital inputs (DIs) on the reComputer allow you to either reduce the charging power or pause all charging sessions during an active external load limiting signal.

### ⚙️ 7. Simple Configuration
Just a single configuration file. SiincosCharge abstracts hardware complexity. Simply configure your edge device (e.g., Raspberry Pi) by following our guide, connect a supported wallbox, and you are ready to go. (In some cases the EV charger or power meter may require some minor configuration, but this will be described in our documentation.)

---

## Architecture

SiincosCharge consists of an edge component, a robust backend ecosystem and a pre-built web interface that you use in any browser:

*   **SiincosCharge Edge (this repo):** Runs locally on your edge device (e.g., Raspberry Pi). It communicates directly with your EV chargers and power meters via ModbusRTU and securely pushes telemetry data to your private backend.

*   **Backend (this repo):** Powered by ThingsBoard CE. This repository contains the configuration assets, device profiles and links to documentation you need to get your private cloud instance up and running effortlessly.

*   **SiincosCharge Web (this repo):** Pre-built ThingsBoard dashboards for monitoring and controlling your charging points: real-time power, session data and history; in addition starting, stopping, pausing and resuming charging sessions. They run in any browser, including browsers on your phone. Together with the edge component and backend make SiincosCharge a complete system that works on its own.

*   **SiincosCharge App (optional, coming soon):** Native apps for Apple platforms (iOS, iPadOS, macOS) that connect directly to your private cloud instance, adding improved mobile usability and PDF reports. The apps are closed source and will be available as a one-time purchase, which supports the continued development of this open-source project. Android is currently planned.

![Siincos Charge System Architecture](https://github.com/JoooHannesk/SiincosCharge/blob/main/SiincosChargeEdge/Sources/SiincosChargeEdge/SiincosChargeEdge.docc/SystemArchitecture.jpg)

---

## Installation & Documentation

The documentation is currently a work in progress and will be linked here as soon as the first version is ready.

---

## Requirements & Supported Hardware

*   **Edge Hardware:** reComputer R1124-10, Raspberry Pi 4 / 5, or any compatible Linux-based IoT device. 
    *   *Note on Serial Connectivity:* Your hardware must feature **at least one** RS485 transceiver. While using a standard USB-to-RS485 dongle is completely fine, please note that concurrently connecting a ModbusRTU charger and a dedicated ModbusRTU power meter requires two separate RS485 transceivers.
*   **Supported Chargers & Power Meters:** Any compatible EV charger or power meter communicating via ModbusRTU (ModbusTCP coming soon). Check our documentation for the full list of compatible devices.

---

## Contributing

We love contributions! Whether you want to add a Modbus profile for a new model, fix a bug, or improve the documentation – feel free to open an issue or submit a pull request. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to get started.

## License

This project is licensed under the **Apache License 2.0**. You are free to use, modify, and distribute the software, as long as the original copyright is preserved. The SiincosCharge apps and any hosted services are separate products and are not covered by it.

---

This README was reviewed for readability, spelling and grammar using AI-assisted tools.

---
*Developed and maintained with 💜 by [Johannes Kinzig](https://johanneskinzig.com/about-me-johannes-kinzig.html)*
