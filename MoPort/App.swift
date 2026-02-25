//
//  App.swift
//  MoPort
//
//  NSApplicationDelegate - Application lifecycle management
//

import Cocoa
import os.log

let log = OSLog(subsystem: "com.moport.app", category: "main")

// File logging helper
private func fileLog(_ message: String) {
    if let file = fopen("/tmp/moport_debug.log", "a") {
        defer { fclose(file) }
        let timestamp = DateFormatter().string(from: Date())
        fputs("[\(timestamp)] \(message)\n", file)
        fflush(file)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var monitor: SerialMonitor!
    private var menuController: MenuBarController!
    private var toast: ToastWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize components
        monitor = SerialMonitor()
        menuController = MenuBarController()

        // Set up callbacks
        monitor.onDeviceAttached = { [weak self] device in
            self?.handleDeviceAttached(device)
        }

        monitor.onDeviceDetached = { [weak self] path in
            self?.handleDeviceDetached(path)
        }

        // Start monitoring
        monitor.startMonitoring()

        // Delayed update to get existing devices
        // Use tracked device list from SerialMonitor
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.updateMenuWithTrackedDevices()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stopMonitoring()
    }

    // MARK: - Device event handling

    private func updateMenuWithTrackedDevices() {
        // Get tracked devices from SerialMonitor
        let devices = monitor.getTrackedDevices()
        os_log("Found %d tracked serial devices", log: log, type: .info, devices.count)
        for device in devices {
            os_log("Adding device to menu: %{public}@", log: log, type: .info, device.path)
            menuController.addDevice(device)
        }
    }

    private func handleDeviceAttached(_ device: SerialDevice) {
        os_log("Device attached: %{public}@", log: log, type: .info, device.path)
        DispatchQueue.main.async {
            // 1. Copy to clipboard
            ClipboardManager.copy(device.path)

            // 2. Show Toast (lazy init)
            if self.toast == nil {
                self.toast = ToastWindow()
            }
            self.toast?.show(device: device, type: .attached)

            // 3. Update menu
            self.menuController.addDevice(device)
        }
    }

    private func handleDeviceDetached(_ path: String) {
        os_log("Device detached: %{public}@", log: log, type: .info, path)
        fileLog("App.handleDeviceDetached: \(path)")
        DispatchQueue.main.async {
            // 1. Show Toast
            if self.toast == nil {
                self.toast = ToastWindow()
            }
            self.toast?.show(path: path, type: .detached)

            // 2. Update menu
            self.menuController.removeDevice(path: path)
        }
    }
}
