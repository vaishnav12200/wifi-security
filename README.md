# 🛡️ CyberShield WiFi

> **Intelligent Public WiFi Security Analyzer for Android**  
> A final-year engineering project with startup potential — built with Flutter.

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter" />
  <img src="https://img.shields.io/badge/Platform-Android-green?logo=android" />
  <img src="https://img.shields.io/badge/License-MIT-yellow" />
  <img src="https://img.shields.io/badge/Status-Stable-brightgreen" />
</p>

---

## 📖 Table of Contents

1. [About](#about)
2. [Features](#features)
3. [Architecture](#architecture)
4. [Prerequisites](#prerequisites)
5. [Installation & Setup](#installation--setup)
6. [Running the App](#running-the-app)
7. [Usage Guide (Step by Step)](#usage-guide-step-by-step)
8. [Building a Release APK](#building-a-release-apk)
9. [Project Structure](#project-structure)
10. [Tech Stack](#tech-stack)
11. [Disclaimer](#disclaimer)

---

## About

**CyberShield WiFi** protects users _before_ they connect to public WiFi networks. It analyzes nearby wireless networks, calculates an AI-style heuristic safety score (0–100), and explains potential threats in plain English — all running **100% on-device** with no backend server required.

Designed as a mobile-first standalone app, it is suitable for cybersecurity demonstrations, engineering project showcases, and everyday public WiFi safety checks.

---

## Features

| Feature | Description |
|---------|-------------|
| 📡 **Network Scanner** | Lists nearby WiFi networks with SSID, BSSID, signal strength, encryption type |
| 🔢 **Safety Score (0–100)** | Heuristic engine scores each network on multiple risk vectors |
| ☠️ **Threat Detection** | Detects weak encryption, open networks, suspicious SSIDs, typosquatting |
| 🧪 **Simulated Lab Mode** | Interactive sliders to simulate ARP spoofing, DNS hijacking, Rogue DHCP |
| 📊 **Live Dashboard** | Real-time latency, bandwidth speed, gateway/DNS info, live line chart |
| 🔔 **Security Alerts** | In-app snackbar and log alerts for critical threats |
| 📜 **Scan History** | SQLite-backed audit log of all past scans |
| 📄 **PDF Reports** | Generate and share professional security audit PDFs |
| ⚙️ **Settings** | AI sensitivity, notification preferences, data management |

---

## Architecture

```
cybershield_wifi/
├── lib/
│   ├── main.dart                  # App entry point, navigation shell
│   ├── theme/
│   │   └── app_theme.dart         # Cyberpunk dark theme (neon cyan + purple)
│   ├── models/
│   │   ├── wifi_network.dart      # Network data model
│   │   ├── threat_alert.dart      # Threat alert model
│   │   └── scan_history.dart      # Scan history model
│   ├── database/
│   │   └── db_helper.dart         # SQLite helper (scan logs, threats, trusted nets)
│   ├── services/
│   │   ├── threat_engine.dart     # Safety scoring, SSID similarity, VPN flags
│   │   ├── network_service.dart   # Ping, bandwidth, DNS, interface lookups
│   │   └── pdf_service.dart       # PDF report generation
│   ├── widgets/
│   │   └── safety_meter.dart      # Animated custom-painted safety dial
│   └── screens/
│       ├── dashboard_screen.dart  # Main telemetry & live monitoring
│       ├── scanner_screen.dart    # Nearby networks + threat simulation
│       ├── threat_details_screen.dart # Threat deep-dive + checklist
│       ├── history_screen.dart    # Audit log + PDF export
│       ├── settings_screen.dart   # App preferences
│       └── about_screen.dart      # Project info & compliance
└── pubspec.yaml
```

---

## Prerequisites

Make sure you have the following installed on your machine:

| Tool | Version | Link |
|------|---------|------|
| Flutter SDK | ≥ 3.10.0 | [flutter.dev](https://flutter.dev/docs/get-started/install) |
| Dart SDK | ≥ 3.0.0 | Bundled with Flutter |
| Android Studio / VS Code | Latest | [developer.android.com](https://developer.android.com/studio) |
| Android SDK | API 21+ | Via Android Studio SDK Manager |
| Java JDK | 17+ | [adoptium.net](https://adoptium.net/) |

---

## Installation & Setup

### 1. Clone the repository

```bash
git clone https://github.com/your-username/cybershield-wifi.git
cd cybershield-wifi
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Verify your Flutter environment

```bash
flutter doctor
```

Ensure no critical issues are reported (Android toolchain should be ✅).

### 4. Connect an Android device **or** start an emulator

**Physical device:**
- Enable **Developer Options** on your Android phone
- Enable **USB Debugging**
- Connect via USB and run `adb devices` to confirm it's detected

**Emulator:**
- Open Android Studio → Device Manager → Create/start an AVD (API 21 or higher)

---

## Running the App

```bash
# List available devices
flutter devices

# Run in debug mode (hot reload enabled)
flutter run

# Run on a specific device
flutter run -d <device-id>
```

The app will launch automatically on your connected device or emulator.

---

## Usage Guide (Step by Step)

### 🏠 Step 1 — Dashboard (Home Screen)

1. Open the app. The **Dashboard** tab is shown first.
2. The app automatically detects your **current active WiFi connection**.
3. You'll see:
   - **Safety Score dial** (0–100) — green is safe, red is dangerous.
   - **Latency** and **Bandwidth** metric tiles.
   - **Gateway IP**, **DNS Server**, **Local IP**, and **Encryption type**.
4. Tap **AUDIT** button (top-right of the connection card) to trigger a full security check.
5. Toggle **MONITOR** switch to enable continuous background monitoring (updates every 10 seconds).
6. Scroll down to see the **Live Latency Graph** and **Security Alerts Log**.

---

### 📡 Step 2 — Scanner (Network Scanner)

1. Tap the **Scanner** tab (radar icon) in the bottom navigation.
2. The screen lists all **nearby WiFi networks** with:
   - SSID name and signal strength (RSSI in dBm)
   - Encryption type (WPA3 / WPA2 / WEP / Open)
   - Safety score badge (colour-coded)
3. Tap **SCAN** button to refresh the list.
4. Tap any network card to open its **Threat Details screen**.

#### 🧪 Simulated Lab Mode (Demo / Educational)

Scroll to the bottom of the Scanner screen to find the **Threat Simulation Lab**:

| Slider | What it Simulates |
|--------|-------------------|
| **ARP Spoofing** | Man-in-the-Middle attack via ARP cache poisoning |
| **DNS Hijacking** | Rogue DNS resolving domains to malicious IPs |
| **Rogue DHCP** | Fake DHCP server assigning attacker-controlled gateway |

- Turn on any slider to inject that threat into the current network scan.
- The safety score will drop and alerts will appear in the Dashboard.
- Use this for **project demonstrations and cybersecurity presentations**.

---

### ⚠️ Step 3 — Threat Details

1. After tapping a network in the Scanner, the **Threat Details** screen opens.
2. You'll see:
   - **Risk level** (Safe / Low / Medium / High / Critical)
   - **Plain-English explanation** of each detected threat
   - **Technical analysis** (encryption, BSSID anomalies, SSID similarity score)
   - **Defensive checklist** — recommended actions to stay safe
3. Scroll down for the full **Protection Recommendations** (e.g., use VPN, avoid sensitive logins).

---

### 📜 Step 4 — History (Audit Log)

1. Tap the **History** tab (clock icon).
2. All past scans are listed in reverse-chronological order with:
   - Network name, safety score, threat count, timestamp
3. Tap any history entry to expand its details.
4. Tap the **📄 Export PDF** button to generate a professional security audit report.
5. The share sheet opens — you can save or send the PDF via any app (WhatsApp, Email, Drive, etc.).

---

### ⚙️ Step 5 — Settings

1. Tap the **Settings** tab (gear icon).
2. Configure:
   - **AI Sensitivity** — how aggressively threats are flagged (Low / Medium / High)
   - **Notification Alerts** — enable/disable threat notifications
   - **Auto-scan on connect** — scan automatically when joining a new WiFi
3. Tap **Clear All Scan History** to wipe the SQLite database.
4. Tap **Clear Threat Alerts** to reset the alert log.

---

### ℹ️ Step 6 — About

1. Tap the **About** tab (info icon).
2. Read project objectives, technology architecture, and the regulatory compliance disclaimer.

---

## Building a Release APK

When you're ready to distribute or submit the project:

```bash
# Build a release APK (unsigned)
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk
```

To build a signed APK for Play Store submission, follow the [Flutter signing guide](https://docs.flutter.dev/deployment/android).

---

## Project Structure

```
lib/
├── main.dart
├── theme/app_theme.dart
├── models/
│   ├── wifi_network.dart
│   ├── threat_alert.dart
│   └── scan_history.dart
├── database/db_helper.dart
├── services/
│   ├── threat_engine.dart
│   ├── network_service.dart
│   └── pdf_service.dart
├── widgets/safety_meter.dart
└── screens/
    ├── dashboard_screen.dart
    ├── scanner_screen.dart
    ├── threat_details_screen.dart
    ├── history_screen.dart
    ├── settings_screen.dart
    └── about_screen.dart
```

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart) |
| **UI Theme** | Material 3 Dark + Cyberpunk Neon |
| **Fonts** | Google Fonts — Outfit & Inter |
| **Database** | SQLite via `sqflite` |
| **Charts** | `fl_chart` — live line graphs |
| **PDF** | `pdf` package — vector PDF generation |
| **Sharing** | `share_plus` — native share sheet |
| **Threat Engine** | Custom Levenshtein-distance SSID similarity + rule-based scoring |
| **Connectivity** | `network_info_plus`, raw socket ping, HTTP bandwidth test |

---

## Disclaimer

> **CyberShield WiFi** is a **defensive, educational** network security tool.  
> It does **not** perform unauthorized packet injection, network attacks, or illegal interception.  
> The "Simulated Lab Mode" generates synthetic threat data for **demonstration purposes only** and does not affect real networks.  
> Network safety scores are **heuristic approximations** and may not detect all custom hardware-level attacks.  
> Always use a trusted VPN on public WiFi networks.

---

## 📜 License

MIT License — feel free to use, modify, and distribute with attribution.

---

<p align="center">Made with ❤️ as a Final Year Engineering Project</p>
