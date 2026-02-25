//
//  MenuBarController.swift
//  MoPort
//
//  状态栏菜单管理 - Apple 原生风格
//

import Cocoa
import os.log
import ServiceManagement

let menuLog = OSLog(subsystem: "com.moport.app", category: "menu")

class MenuBarController {
    // MARK: - 私有属性

    private var statusItem: NSStatusItem?
    private var connectedDevices: Set<SerialDevice> = []

    // MARK: - 初始化

    init() {
        setupStatusItem()
        setupLanguageObserver()
        updateMenu()
    }

    // MARK: - 私有方法

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "cable.connector", accessibilityDescription: "MoPort")
            button.image?.isTemplate = true
        }
    }

    private func setupLanguageObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(languageChanged),
            name: .languageChanged,
            object: nil
        )
    }

    @objc private func languageChanged() {
        updateMenu()
    }

    private func updateMenu() {
        statusItem?.menu = nil

        let menu = NSMenu()

        // ===== 串口设备 =====
        if connectedDevices.isEmpty {
            let emptyItem = NSMenuItem()
            emptyItem.title = L("noDevices")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for device in connectedDevices.sorted(by: { $0.connectedAt < $1.connectedAt }) {
                menu.addItem(createDeviceMenuItem(device))
            }
        }

        // ===== 分隔线 =====
        menu.addItem(NSMenuItem.separator())

        // 语言
        menu.addItem(createLanguageMenuItem())

        // 开机自启 - 检查实际状态
        let launchEnabled = isLoginItemEnabled()
        let launchItem = NSMenuItem()
        launchItem.title = L("launchAtLogin")
        launchItem.state = launchEnabled ? .on : .off
        launchItem.action = #selector(toggleLaunchAtLogin(_:))
        launchItem.target = self
        menu.addItem(launchItem)

        // 关于
        let aboutItem = NSMenuItem()
        aboutItem.title = L("about")
        aboutItem.action = #selector(showAbout)
        aboutItem.target = self
        menu.addItem(aboutItem)

        // ===== 退出 =====
        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem()
        quitItem.title = L("quit")
        quitItem.action = #selector(NSApplication.terminate(_:))
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // 创建设备菜单项 (Apple 风格)
    private func createDeviceMenuItem(_ device: SerialDevice) -> NSMenuItem {
        let item = NSMenuItem()
        item.title = device.path

        item.action = #selector(copyDevicePath(_:))
        item.target = self
        item.representedObject = device
        item.toolTip = L("clickToCopy")

        return item
    }

    // 创建语言菜单项 (Apple 风格子菜单)
    private func createLanguageMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        item.title = L("language")

        // 创建子菜单
        let languageMenu = NSMenu()

        let languages = [Language.chinese, Language.english]
        for lang in languages {
            let langItem = NSMenuItem()
            langItem.title = "  " + lang.displayName
            if lang == Localization.shared.currentLanguage {
                langItem.state = .on
            }
            langItem.action = #selector(setLanguage(_:))
            langItem.target = self
            langItem.representedObject = lang
            languageMenu.addItem(langItem)
        }

        item.submenu = languageMenu
        return item
    }

    // MARK: - 公开方法

    func addDevice(_ device: SerialDevice) {
        os_log("Adding device: %{public}@, current count: %d",
               log: menuLog, type: .info, device.path, connectedDevices.count)
        connectedDevices.insert(device)
        os_log("After add, count: %d", log: menuLog, type: .info, connectedDevices.count)
        updateMenu()
    }

    func removeDevice(path: String) {
        let tempDevice = SerialDevice(path: path)
        let removed = connectedDevices.remove(tempDevice)
        os_log("Removing device: %{public}@, removed: %{public}@, remaining: %d",
               log: menuLog, type: .info, path, removed != nil ? "yes" : "no", connectedDevices.count)
        updateMenu()
    }

    // MARK: - Actions

    @objc private func copyDevicePath(_ sender: NSMenuItem) {
        if let device = sender.representedObject as? SerialDevice {
            ClipboardManager.copy(device.path)
            showCopyFeedback()
        }
    }

    private func showCopyFeedback() {
        // 短暂显示已复制状态
        if let button = statusItem?.button {
            let checkmark = NSImage(systemSymbolName: "checkmark.circle.fill", accessibilityDescription: "copied")
            checkmark?.isTemplate = false

            button.image = checkmark

            // 0.5秒后恢复
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                button.image = NSImage(systemSymbolName: "cable.connector", accessibilityDescription: "MoPort")
                button.image?.isTemplate = true
            }
        }
    }

    @objc private func setLanguage(_ sender: NSMenuItem) {
        if let lang = sender.representedObject as? Language {
            Localization.shared.setLanguage(lang)
        }
    }

    // 检查登录项是否已启用
    private func isLoginItemEnabled() -> Bool {
        // 使用 UserDefaults 存储用户偏好
        return UserDefaults.standard.bool(forKey: "launchAtLogin")
    }

    @objc private func toggleLaunchAtLogin(_ sender: NSMenuItem) {
        let newState = sender.state == .off

        // 切换状态并保存
        sender.state = newState ? .on : .off
        UserDefaults.standard.set(newState, forKey: "launchAtLogin")

        // 显示提示
        showLaunchAtLoginHint(enabled: newState)
    }

    private func showLaunchAtLoginHint(enabled: Bool) {
        let alert = NSAlert()
        alert.messageText = L("launchAtLogin")
        alert.informativeText = enabled
            ? "请在「系统设置 → 通用 → 登录项」中添加 MoPort"
            : "请在「系统设置 → 通用 → 登录项」中移除 MoPort"
        alert.alertStyle = .informational
        alert.addButton(withTitle: L("ok"))
        alert.runModal()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "MoPort"
        alert.alertStyle = .informational

        // 从 Bundle 资源加载自定义图标
        if let iconPath = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
           let icon = NSImage(contentsOfFile: iconPath) {
            alert.icon = icon
        }

        alert.informativeText = """
        \(L("appName")) \(L("version")) \(appVersion)

        \(L("appDescription"))

        \(L("aboutInfo"))
        """

        alert.addButton(withTitle: L("ok"))
        alert.runModal()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
