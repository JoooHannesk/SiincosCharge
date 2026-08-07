# SiincosCharge

An open-source, privacy-first EV charging infrastructure management system designed for multi-location deployment and decentralized control. Take back your data and manage all your charging points across different locations through elegant dashboards – without being locked into proprietary cloud providers or restrictive corporate ecosystems.

![Siincos Charge Dashboard with 3 charging points, one is currently charging](https://github.com/JoooHannesk/SiincosCharge/blob/main/SiincosChargeEdge/Sources/SiincosChargeEdge/SiincosChargeEdge.docc/SiincosCharge3CpDashboard2notChargingFullscreen.png)

## 🚀 The Vision
Many modern EV charging solutions rely on proprietary cloud backends that limit data ownership, customization and integration possibilities.

**SiincosCharge bridges this gap.** It provides a production-ready, cloud-enabled open-source core that runs on lightweight edge devices (like a Raspberry Pi), offering multi-site management and data sovereignty. By utilizing **ThingsBoard CE** as its decentralized backend foundation, SiincosCharge delivers an enterprise-grade IoT architecture directly into your hands – without corporate vendor lock-in.

## 🧩 What SiincosCharge is (and is not)
| 🟣 SiincosCharge focus | ⚪ Outside the scope |
|---|---|
| An open-source IoT-based management system for operating, monitoring and integrating EV charging infrastructure. Focused on multi-location deployments, device integration, telemetry, remote management and data sovereignty. | Not a smart charging optimizer. It does not provide PV surplus charging, vehicle charging strategies or energy management algorithms. Instead, it provides an operational infrastructure layer to connect, monitor and operate charging points reliably. |

---

## 🥾 Core Motivation

### 🏢 1. Multi-Location Management
Manage multiple charging points across various physical locations (e.g., your home, your office, your business location, your vacation rental) in a single unified interface. Monitor real-time power consumption, set load limits, and aggregate historical charging data effortlessly.

### 👥 2. Charger Sharing
Want to share your charger with friends, neighbors or employees? Authorize users directly within your ThingsBoard CE tenant. SiincosCharge tracks precise energy consumption, aggregates detailed statistics, and automatically generates detailed charging session reports.

### 🛡️ 3. Data Sovereignty (Private Cloud)
Your charging data belongs to you. SiincosCharge is natively cloud-enabled but designed to run on *your* infrastructure. By hosting your own open-source backend based on ThingsBoard CE, you get full remote access and a seamless user experience – without sharing telemetry or user data with third-party vendors.

### ⚡️ 4. Load Balancing & Grid Compliance (§ 14a EnWG - German regulation)
*   **Dynamic Load Management:** Automatic load balancing in case multiple EV chargers are operating concurrently. The system dynamically adjusts the charging current per station to ensure the overall electrical installation limit is never exceeded.
*   **Grid Operator Curtailment (Ready for § 14a EnWG):** Designed with strict German grid regulations in mind. The system is architected to interface with a digital grid operator receiver (e.g., via a dry-contact / potential-free input on the edge hardware) to temporarily dim or pause charging sessions down to the legally mandated minimum (e.g., 4.2 kW). *Note: The dry-contact hardware trigger integration is currently under active development and will be released in an upcoming update.*

### ⚙️ 5. Simple Configuration
Just a single configuration file. SiincosCharge abstracts hardware complexity. Simply configure your edge device (e.g., Raspberry Pi) by following our guide, connect a supported wallbox, and you are ready to go. (In some cases the EV-charger or Power Meter may require some minor configuration, but this will be described in our documentation.)

---

## 🔩 Architecture

SiincosCharge is split into a lightweight edge component, a robust backend ecosystem, and a modern mobile client to ensure maximum security and scalability:

*   **SiincosCharge Edge (This Repo):** The lightweight open-source firmware running locally on your edge device (e.g., Raspberry Pi). It communicates directly with your EV chargers and power meters via Modbus (TCP/RTU) and securely pushes telemetry data to your private backend.
*   **Backend (This Repo):** Powered by ThingsBoard CE. This repository contains all the necessary configuration assets, links to documentation, device profiles and pre-built IoT dashboards to get your private cloud instance up and running effortlessly.
*   **SiincosCharge App (Optional, coming soon):** Our native iOS and Android app (both coming soon) that hook directly into your private cloud instance, adding improved usability for mobile devices including advanced reporting and statistics.

![Siincos Charge System Architecture](https://github.com/JoooHannesk/SiincosCharge/blob/main/SiincosChargeEdge/Sources/SiincosChargeEdge/SiincosChargeEdge.docc/System-Architecture.jpg)
---

## 📋 Requirements & Supported Hardware

*   **Edge Hardware:** reComputer R1124-10, Raspberry Pi 4 / 5, or any compatible Linux-based IoT gateway. 
    *   *Note on Serial Connectivity:* Your hardware must feature **at least one** RS485 transceiver. While using a standard USB-to-RS485 dongle is completely fine, please note that concurrently connecting a ModbusRTU charger and a dedicated ModbusRTU power meter requires two separate RS485 transceivers.
*   **Supported Chargers & Power Meters:** Any compatible EV charger or power meter communicating via ModbusRTU (ModbusTCP coming soon). Check our documentation for the full list of compatible devices.

---

## 🤝 Contributing

We love contributions! Whether you want to add a Modbus profile for a new model, fix a bug, or improve the documentation – feel free to open an issue or submit a pull request. 

## ⚖️ License

This project is licensed under the **Apache License 2.0** / **MIT License**. You are free to use, modify, and distribute the core software, as long as the original copyright is preserved.

---

This README was reviewed for readability, spelling and grammar using AI-assisted tools.

---
*Developed and maintained with ☕ by [Johannes Kinzig](https://johanneskinzig.com) / [JoooHannesk](https://github.com/JoooHannesk).*
