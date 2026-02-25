//
//  Localization.swift
//  MoPort
//
//  多语言支持
//

import Foundation

enum Language: String {
    case english = "en"
    case chinese = "zh"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

class Localization {
    static let shared = Localization()

    private(set) var currentLanguage: Language {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }

    private init() {
        if let langCode = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = Language(rawValue: langCode) {
            currentLanguage = lang
        } else {
            // 根据系统语言自动选择
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            currentLanguage = systemLang.hasPrefix("zh") ? .chinese : .english
        }
    }

    func setLanguage(_ language: Language) {
        currentLanguage = language
    }

    func localizedString(_ key: String) -> String {
        switch currentLanguage {
        case .english:
            return englishStrings[key] ?? key
        case .chinese:
            return chineseStrings[key] ?? key
        }
    }
}

// MARK: - 版本号

let appVersion = "0.0.6"

// MARK: - 字符串定义

private let englishStrings: [String: String] = [
    "appName": "MoPort",
    "noDevice": "No serial devices",
    "noDevices": "No Devices",
    "launchAtLogin": "Open at Login",
    "quit": "Quit",
    "deviceFound": "Serial connected",
    "deviceRemoved": "Serial disconnected",
    "language": "Language",
    "deviceGroup": "Serial Ports",
    "settings": "Settings",
    "about": "About MoPort…",
    "clickToCopy": "Click to copy path",
    "copied": "Copied to clipboard",
    "appDescription": "macOS Serial Port Monitor for ESP32/Arduino",
    "aboutInfo": "A lightweight tool for embedded developers.\n\n© 2026 MoPort Project\nby MoveCall",
    "version": "Version",
    "preferences": "Preferences",
    "ok": "OK"
]

private let chineseStrings: [String: String] = [
    "appName": "MoPort",
    "noDevice": "无串口设备",
    "noDevices": "无设备",
    "launchAtLogin": "会在登录时打开",
    "quit": "退出 MoPort",
    "deviceFound": "发现串口",
    "deviceRemoved": "串口断开",
    "language": "语言",
    "deviceGroup": "串口",
    "settings": "设置",
    "about": "关于 MoPort…",
    "clickToCopy": "点击复制路径",
    "copied": "已复制到剪贴板",
    "appDescription": "macOS 串口监听工具 (ESP32/Arduino)",
    "aboutInfo": "一款轻量级嵌入式开发辅助工具。\n\n© 2026 MoPort 项目\n作者: MoveCall",
    "version": "版本",
    "preferences": "偏好设置",
    "ok": "好"
]

// MARK: - 便捷访问

func L(_ key: String) -> String {
    return Localization.shared.localizedString(key)
}

// MARK: - Notification

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}
