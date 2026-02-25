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

1. 下载 [MoPort-v0.0.6.dmg](https://github.com/MoveCall/MoPort/releases/download/v0.0.6/MoPort-v0.0.6.dmg)
2. 打开 DMG 并将 MoPort.app 拖到 Applications 文件夹
3. 右键点击 MoPort.app，选择"打开"

**注意**: 首次打开时 macOS 可能会提示安全警告。这是因为应用未使用 Apple Developer 证书签名。如需运行：

- 进入 **系统设置 → 隐私与安全性**
- 在"已阻止使用 MoPort"处点击"仍要打开"

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

MoveCall - [GitHub](https://github.com/movecall)

## 许可证

© 2026 MoPort Project
