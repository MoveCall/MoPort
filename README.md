# MoPort

**macOS Serial Port Monitor**

A lightweight serial port monitoring tool for embedded developers (ESP32, Arduino, etc.). Provides instant visual feedback and automatically copies serial port paths to clipboard when USB-to-Serial devices are connected or disconnected.

<p align="center">
  <a href="https://github.com/MoveCall/MoPort/releases"><img src="https://img.shields.io/github/v/release/MoveCall/MoPort?style=flat-square" alt="GitHub release"></a>
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/%E4%B8%AD%E6%96%87-0e6586?style=flat-square" alt="中文"></a>
  <a href="README.md"><img src="https://img.shields.io/badge/English-0e6586?style=flat-square" alt="English"></a>
</p>

## Screenshot

![MoPort Screenshot](assets/connected.png)

## Features

- 🔌 Auto-detect serial port connect/disconnect
- 📋 Auto-copy serial path to clipboard
- 🔔 Toast notification for device status
- 🌍 Support for Chinese/English interface

## Installation

Download [MoPort-v0.0.6.dmg](https://github.com/MoveCall/MoPort/releases/download/v0.0.6/MoPort-v0.0.6.dmg) and drag to Applications folder.

**Requirements**: macOS 13.0+, Apple Silicon

## Usage

After launching, the app icon appears in the menu bar. When a serial device is connected, the path is automatically copied to the clipboard.

## Build

```bash
make        # Build
make run    # Run
make clean  # Clean
```

## Author

MoveCall - [GitHub](https://github.com/MoveCall)

## License

© 2026 MoPort Project
