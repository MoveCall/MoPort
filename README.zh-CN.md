# MoPort

**macOS 串口监听工具**

MoPort 是一款为嵌入式开发者（ESP32、Arduino 等）设计的 macOS 原生轻量级串口监听工具。当 USB-to-Serial 设备接入或拔出时，提供即时视觉反馈并自动复制串口路径到剪贴板。

<p align="center">
  <a href="https://github.com/MoveCall/MoPort/releases"><img src="https://img.shields.io/github/v/release/MoveCall/MoPort?style=flat-square" alt="GitHub release"></a>
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/%E4%B8%AD%E6%96%87-0e6586?style=flat-square" alt="中文"></a>
  <a href="README.md"><img src="https://img.shields.io/badge/English-0e6586?style=flat-square" alt="English"></a>
</p>

## 截图

![MoPort 截图](assets/connected.png)

## 功能

- 🔌 自动监听串口设备插入/拔出
- 📋 自动复制串口路径到剪贴板
- 🔔 悬浮气泡提示设备状态
- 🌍 支持中文/英文界面

## 安装

下载 [MoPort-v0.0.6.dmg](https://github.com/MoveCall/MoPort/releases/download/v0.0.6/MoPort-v0.0.6.dmg)，拖拽到 Applications 文件夹。

**系统要求**: macOS 13.0+, Apple Silicon

## 使用

运行后应用在菜单栏显示图标。插入串口设备时自动复制路径到剪贴板。

## 编译

```bash
make        # 编译
make run    # 运行
make clean  # 清理
```

## 作者

MoveCall - [GitHub](https://github.com/MoveCall)

## 许可证

© 2026 MoPort Project
