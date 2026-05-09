# Quantum Sun

**Quantum Sun** is a macOS status bar application (menu bar app) written in Swift. It provides real-time network traffic monitoring and displays your current public IP address along with a country flag.

## Project Overview

*   **Type:** macOS Application (Agent/Status Bar app)
*   **Language:** Swift (AppKit/Cocoa)
*   **Key Features:**
    *   **Real-time Network Monitor:** Displays upload/download speeds in the menu bar.
    *   **IP Address Display:** Shows public IP and country flag (fetched from `ipapi.co`).
    *   **Visual Graph:** Includes a "Retro Terminal" style graph in the dropdown menu to visualize traffic history.
    *   **Minimalist:** Designed to sit quietly in the status bar (`LSUIElement` is set to `true`).

## Architecture

*   **Entry Point:** `Sources/main.swift` contains the entire application logic, including the `AppDelegate`, `NetworkMonitor`, and `TerminalGraphView`.
*   **Network Monitoring:** Uses `getifaddrs` to access low-level network interface statistics (bytes in/out).
*   **Building:** Uses Swift Package Manager for compilation and a shell script for `.app` bundling.

## Building and Running

### Prerequisites
*   macOS with Xcode Command Line Tools installed.
*   Swift 5.9 or later.

### Build and Package (Recommended)
The project includes a helper script to build the release binary and package it into a standard `.app` bundle.

```bash
./install.sh
```

This will:
1.  Run `swift build -c release`.
2.  Create the `QuantumSun.app` directory structure.
3.  Generate an `AppIcon.icns` from `AppIcon.png` (if present).
4.  Copy the executable and `Info.plist` into the bundle.

**Output:** `QuantumSun.app` in the project root.

### Run Directly (Debug)
You can run the executable directly via Swift PM, though it won't have the full app bundle context (icon, plist info) associated with it during development.

```bash
swift run
```

## Development Conventions

*   **Single File Logic:** Currently, all application code resides in `Sources/main.swift`.
    *   **Models:** `IPResponse`
    *   **Logic:** `NetworkMonitor`
    *   **UI/Lifecycle:** `AppDelegate`
    *   **Views:** `TerminalGraphView`
*   **UI Framework:** AppKit (Cocoa). No Storyboards or XIBs; UI is constructed programmatically.
*   **Configuration:** `Info.plist` controls app metadata (e.g., `LSUIElement` to hide from Dock).
*   **Networking:** Uses `URLSession` for API calls and low-level BSD sockets (`getifaddrs`) for traffic stats.

## Key Files

*   `Sources/main.swift`: The main source code.
*   `Package.swift`: Swift Package Manager configuration.
*   `install.sh`: Build and packaging script.
*   `Info.plist`: Application property list.
