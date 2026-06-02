# SiincosCharge

An open-source, privacy-first EV charging management system designed for multi-location deployment and decentralized control. Take back your data and manage all your charging points across different locations through elegant dashboards – without relying on third-party cloud providers or restrictive corporate ecosystems.

## 🚀 The Vision

Modern EV charging infrastructure mainly operates on closed corporate cloud backends that lock away your data and charge premium monthly fees for advanced features and API access.

**SiincosCharge bridges this gap.** It provides a production-ready, cloud-enabled open-source core that runs on lightweight edge devices (like a Raspberry Pi), offering multi-site management and data sovereignty. By utilizing **ThingsBoard CE** as its decentralized backend foundation, SiincosCharge delivers an enterprise-grade IoT architecture directly into your hands – without corporate vendor lock-in.

---

## ✨ Core Pillars

### 🏢 1. Multi-Location Fleet & Site Management
Manage multiple charging points across various physical locations (e.g., your home, your office, your business location, your vacation rental) in a single unified interface. Monitor real-time consumption, set load limits, and aggregate historical charging data effortlessly.

### 🛡️ 2. Absolute Data Sovereignty (Private Cloud)
Your charging data belongs to you. SiincosCharge is natively cloud-enabled but designed to run on *your* infrastructure. By hosting your own open-source backend based on ThingsBoard CE, you get full remote access and a seamless user experience – without sharing telemetry or user data with third-party vendors.

### 🔌 3. Simple-Configuration Onboarding
Just a single configuration file. SiincosCharge abstracts hardware complexity. Simply configure your edge device (e.g., Raspberry Pi) by following our straightforward guide, connect a supported wallbox, and you are ready to go. (In some cases the EV-charger or Power Meter may require some minor configuration, which will be described in our documentation.)

### 👥 4. Built-in Peer Sharing
Want to share your charger with employees, friends, or neighbors? Authorize users directly within your ThingsBoard CE tenant. SiincosCharge tracks precise energy consumption, aggregates detailed statistics, and automatically generates a receipt for each charging session.

---

## 🛠️ Architecture

SiincosCharge is split into a lightweight edge component, a robust backend ecosystem, and a modern mobile client to ensure maximum security and scalability:

*   **SiincosCharge Edge (This Repo):** The lightweight open-source firmware running locally on your edge device (e.g., Raspberry Pi). It communicates directly with your EV chargers via Modbus (TCP/RTU) and securely pushes telemetry data to your private backend.
*   **Backend (This Repo):** Powered by ThingsBoard CE. This repository contains all the necessary configuration assets, documentation, device profiles and pre-built IoT dashboards to get your private cloud instance up and running effortlessly.
*   **Native App (Optional, coming soon):** Our native iOS app (Android coming soon) that hooks directly into your private instance, adding improved usability for mobile devices including advanced reporting and statistics.

---

## 📋 Requirements & Supported Hardware

*   **Edge Hardware:** reComputer R1124-10, Raspberry Pi 4 / 5, or any compatible Linux-based IoT gateway. 
    *   *Note on Serial Connectivity:* Your hardware must feature **at least one** RS485 transceiver. While using a standard USB-to-RS485 dongle is completely fine, please note that concurrently connecting a ModbusRTU wallbox and a dedicated ModbusRTU power meter requires two separate RS485 transceivers.
*   **Supported Chargers & Power Meters:** Any wallbox or power meter communicating via ModbusRTU (ModbusTCP coming soon). Check our documentation for the full list of compatible devices.

---

## 🤝 Contributing

We love contributions! Whether you want to add a Modbus profile for a new Wallbox model, fix a bug, or improve the documentation – feel free to open an issue or submit a pull request. 

## ⚖️ License

This project is licensed under the **Apache License 2.0** / **MIT License**. You are free to use, modify, and distribute the core software, even for commercial hosting or hardware integration, as long as the original copyright is preserved.

---

This README was reviewed for readability, spelling and grammar using AI-assisted tools.

---
*Developed and maintained with ☕ by [Johannes Kinzig](https://johanneskinzig.com) / [JoooHannesk](https://github.com/JoooHannesk).*
