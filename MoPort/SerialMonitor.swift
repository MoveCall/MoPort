//
//  SerialMonitor.swift
//  MoPort
//
//  IOKit 串口设备监听核心
//

import Foundation
import IOKit
import CoreFoundation
import os.log

let monitorLog = OSLog(subsystem: "com.moport.app", category: "monitor")

// 文件日志辅助函数
private func fileLog(_ message: String) {
    if let file = fopen("/tmp/moport_debug.log", "a") {
        defer { fclose(file) }
        let timestamp = DateFormatter().string(from: Date())
        fputs("[\(timestamp)] \(message)\n", file)
        fflush(file)
    }
}

// MARK: - IOKit 常量定义

let kIOSerialBSDClientValue = "IOSerialBSDClient"
let kIOCalloutDeviceKey = "IOCalloutDevice"
let kIOTTYDeviceKey = "IOTTYDevice"

class SerialMonitor {
    // MARK: - 回调

    var onDeviceAttached: ((SerialDevice) -> Void)?
    var onDeviceDetached: ((String) -> Void)?

    // MARK: - 私有属性

    private var notificationPort: IONotificationPortRef?
    private var attachedIterator: io_iterator_t = 0
    private var detachedIterator: io_iterator_t = 0
    fileprivate var isMonitoring = false

    // 追踪已连接的设备 (path -> SerialDevice)
    private var connectedDevices: [String: SerialDevice] = [:]
    private let queue = DispatchQueue(label: "com.moport.serialmonitor", attributes: .concurrent)
    private var periodicScanTimer: DispatchSourceTimer?

    // 保持上下文对象的引用，防止被过早释放
    private var attachedContextRef: Unmanaged<AttachedContext>?
    private var detachedContextRef: Unmanaged<DetachedContext>?

    // MARK: - 启动/停止

    func startMonitoring() {
        guard !isMonitoring else { return }

        // 创建通知端口
        notificationPort = IONotificationPortCreate(kIOMainPortDefault)
        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort!).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, CFRunLoopMode.commonModes)

        // 匹配串口设备 - 需要创建两个独立的字典
        let attachedMatchingDict = IOServiceMatching(kIOSerialBSDClientValue)
        let detachedMatchingDict = IOServiceMatching(kIOSerialBSDClientValue)

        // 注册设备插入通知 - 保持引用防止被释放
        let attachedCtx = AttachedContext(monitor: self)
        attachedContextRef = Unmanaged.passRetained(attachedCtx)
        let attachedContext = attachedContextRef!.toOpaque()

        let result1 = IOServiceAddMatchingNotification(
            notificationPort!,
            kIOFirstMatchNotification,
            attachedMatchingDict,
            { (refCon, iterator) in
                deviceAttachedCallback(refCon: refCon, iterator: iterator)
            },
            attachedContext,
            &attachedIterator
        )

        // 注册设备拔出通知 - 保持引用防止被释放
        let detachedCtx = DetachedContext(monitor: self)
        detachedContextRef = Unmanaged.passRetained(detachedCtx)
        let detachedContext = detachedContextRef!.toOpaque()

        let result2 = IOServiceAddMatchingNotification(
            notificationPort!,
            kIOTerminatedNotification,
            detachedMatchingDict,
            { (refCon, iterator) in
                deviceDetachedCallback(refCon: refCon, iterator: iterator)
            },
            detachedContext,
            &detachedIterator
        )

        fileLog("startMonitoring: attached result=\(result1), detached result=\(result2)")

        if result1 == KERN_SUCCESS && result2 == KERN_SUCCESS {
            isMonitoring = true

            // 初始遍历已存在的设备
            scanExistingDevices()
        }

        // 启动定期扫描作为备份
        startPeriodicScan()
    }

    func stopMonitoring() {
        guard isMonitoring else { return }

        if attachedIterator != 0 {
            IOObjectRelease(attachedIterator)
            attachedIterator = 0
        }

        if detachedIterator != 0 {
            IOObjectRelease(detachedIterator)
            detachedIterator = 0
        }

        if let port = notificationPort {
            IONotificationPortDestroy(port)
            notificationPort = nil
        }

        // 停止定期扫描
        periodicScanTimer?.cancel()
        periodicScanTimer = nil

        // 释放上下文引用
        attachedContextRef?.release()
        attachedContextRef = nil
        detachedContextRef?.release()
        detachedContextRef = nil

        isMonitoring = false
    }

    // MARK: - 私有方法

    private func scanExistingDevices() {
        var device: io_object_t = 0
        while case let nextDevice = IOIteratorNext(attachedIterator), nextDevice != 0 {
            device = nextDevice
            if let serialDevice = parseDevice(device) {
                connectedDevices[serialDevice.path] = serialDevice
            }
        }
    }

    // 获取当前追踪的所有设备
    func getTrackedDevices() -> [SerialDevice] {
        let devices = queue.sync {
            return Array(connectedDevices.values)
        }
        os_log("getTrackedDevices: count=%d", log: monitorLog, type: .info, devices.count)
        for dev in devices {
            os_log("  - %{public}@ (connectedAt: %{public}@)",
                   log: monitorLog, type: .info, dev.path, dev.connectedAt as NSDate)
        }
        return devices
    }

    // 调试方法：打印当前状态
    func debugPrintState() {
        let devices = queue.sync {
            return Array(connectedDevices.values)
        }
        print("[DEBUG] SerialMonitor tracked devices: \(devices.count)")
        for dev in devices {
            print("[DEBUG]   - \(dev.path)")
        }
    }

    // 启动定期扫描（检测 kIOTerminatedNotification 漏掉的设备）
    private func startPeriodicScan() {
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.moport.periodic"))
        timer.schedule(deadline: .now() + .seconds(2), repeating: .milliseconds(500))
        timer.setEventHandler { [weak self] in
            self?.checkForRemovedDevices()
        }
        timer.resume()
        periodicScanTimer = timer
    }

    // 检查已移除的设备
    private func checkForRemovedDevices() {
        let trackedDevices = queue.sync {
            return Array(connectedDevices.values)
        }

        for device in trackedDevices {
            // 检查设备路径是否仍然存在
            if !fileExistsAtPath(device.path) {
                fileLog("Periodic scan detected removed device: \(device.path)")
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.onDeviceDetached?(device.path)
                }
                // 从追踪列表移除
                _ = internalRemoveDevice(path: device.path)
            }
        }
    }

    // 检查文件是否存在
    private func fileExistsAtPath(_ path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }

    func parseDevice(_ device: io_object_t) -> SerialDevice? {
        // 获取设备路径 (kIODialinDevice 或 kIOCalloutDevice)
        var path: String?
        if let calloutPath = getIOStringProperty(device, key: kIOCalloutDeviceKey) {
            // 只处理 /dev/cu.* (Callout Device)，忽略 /dev/tty.*
            if calloutPath.hasPrefix("/dev/cu.") {
                path = calloutPath
            }
        }

        guard let devicePath = path else { return nil }

        // 获取设备名称
        let name = getIOStringProperty(device, key: kIOTTYDeviceKey) ?? "USB Serial"

        // 获取厂商名称
        let manufacturer = getIOStringProperty(device, key: "USB Vendor Name")

        // 获取 VID/PID
        let vendorID = getIOIntProperty(device, key: "idVendor")
        let productID = getIOIntProperty(device, key: "idProduct")

        return SerialDevice(
            path: devicePath,
            name: name,
            manufacturer: manufacturer,
            vendorID: vendorID,
            productID: productID
        )
    }

    func getIOStringProperty(_ device: io_object_t, key: String) -> String? {
        guard device != 0 else { return nil }
        let cfKey = key as CFString
        guard let property = IORegistryEntryCreateCFProperty(device, cfKey, kCFAllocatorDefault, 0) else {
            return nil
        }
        let result = property.takeRetainedValue() as? String
        return result
    }

    private func getIOIntProperty(_ device: io_object_t, key: String) -> Int? {
        let cfKey = key as CFString
        guard let property = IORegistryEntryCreateCFProperty(device, cfKey, kCFAllocatorDefault, 0) else {
            return nil
        }
        return property.takeRetainedValue() as? Int
    }

    // 内部方法：添加设备到追踪列表
    func internalAddDevice(_ device: SerialDevice) {
        queue.async(flags: .barrier) {
            self.connectedDevices[device.path] = device
        }
    }

    // 内部方法：检查设备是否存在
    func internalHasDevice(path: String) -> Bool {
        return queue.sync {
            let exists = connectedDevices[path] != nil
            os_log("internalHasDevice(%{public}@): %{public}@",
                   log: monitorLog, type: .info, path, exists ? "yes" : "no")
            return exists
        }
    }

    // 内部方法：移除设备并返回
    func internalRemoveDevice(path: String) -> SerialDevice? {
        return queue.sync {
            return connectedDevices.removeValue(forKey: path)
        }
    }
}

// MARK: - 上下文类

private class AttachedContext {
    let monitor: SerialMonitor
    init(monitor: SerialMonitor) { self.monitor = monitor }
}

private class DetachedContext {
    let monitor: SerialMonitor
    init(monitor: SerialMonitor) { self.monitor = monitor }
}

// MARK: - C 回调函数

private func deviceAttachedCallback(refCon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refCon = refCon else { return }
    let context = Unmanaged<AttachedContext>.fromOpaque(refCon).takeUnretainedValue()
    let monitor = context.monitor

    // 弱引用检查，防止在停止监听后继续回调
    guard monitor.isMonitoring else { return }

    var device: io_object_t = 0
    while case let nextDevice = IOIteratorNext(iterator), nextDevice != 0 {
        device = nextDevice

        if let serialDevice = monitor.parseDevice(device) {
            fileLog("ATTACHED: \(serialDevice.path), already tracked: \(monitor.internalHasDevice(path: serialDevice.path))")
            os_log("Device attached callback: %{public}@, already tracked: %{public}@",
                   log: monitorLog, type: .info, serialDevice.path,
                   monitor.internalHasDevice(path: serialDevice.path) ? "yes" : "no")
            // 避免重复触发
            if !monitor.internalHasDevice(path: serialDevice.path) {
                monitor.internalAddDevice(serialDevice)

                DispatchQueue.main.async { [weak monitor] in
                    // 再次检查监听状态
                    guard let monitor = monitor, monitor.isMonitoring else { return }
                    monitor.onDeviceAttached?(serialDevice)
                }
            }
        }

        IOObjectRelease(device)
    }
}

private func deviceDetachedCallback(refCon: UnsafeMutableRawPointer?, iterator: io_iterator_t) {
    guard let refCon = refCon else { return }
    let context = Unmanaged<DetachedContext>.fromOpaque(refCon).takeUnretainedValue()
    let monitor = context.monitor

    // 弱引用检查，防止在停止监听后继续回调
    guard monitor.isMonitoring else { return }

    var device: io_object_t = 0
    while case let nextDevice = IOIteratorNext(iterator), nextDevice != 0 {
        device = nextDevice

        if let path = monitor.getIOStringProperty(device, key: kIOCalloutDeviceKey),
           path.hasPrefix("/dev/cu.") {

            fileLog("DETACHED: \(path)")
            os_log("Device detached callback: %{public}@", log: monitorLog, type: .info, path)

            // 从追踪列表中移除
            if let removedDevice = monitor.internalRemoveDevice(path: path) {
                let removedPath = removedDevice.path
                fileLog("DETACHED: removed from tracker, triggering callback: \(removedPath)")
                os_log("Removed from tracker, triggering callback: %{public}@", log: monitorLog, type: .info, removedPath)
                DispatchQueue.main.async { [weak monitor] in
                    // 再次检查监听状态
                    guard monitor != nil else { return }
                    monitor?.onDeviceDetached?(removedPath)
                }
            } else {
                fileLog("DETACHED: device NOT in tracker: \(path)")
                os_log("Device NOT in tracker: %{public}@", log: monitorLog, type: .info, path)
            }
        }

        IOObjectRelease(device)
    }
}
