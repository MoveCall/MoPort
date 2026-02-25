//
//  SerialDevice.swift
//  MoPort
//
//  Serial device data model
//

import Foundation

/// Serial device information
struct SerialDevice: Hashable {
    let id = UUID()
    let path: String           // /dev/cu.usbserial-1410
    let name: String           // USB Serial
    let manufacturer: String?  // FTDI / WCH / Silicon Labs
    let vendorID: Int?
    let productID: Int?
    let connectedAt: Date

    init(path: String, name: String = "USB Serial", manufacturer: String? = nil,
         vendorID: Int? = nil, productID: Int? = nil, connectedAt: Date = Date()) {
        self.path = path
        self.name = name
        self.manufacturer = manufacturer
        self.vendorID = vendorID
        self.productID = productID
        self.connectedAt = connectedAt
    }

    // MARK: - Hashable

    // Compare by path (same serial path is always unique)
    static func == (lhs: SerialDevice, rhs: SerialDevice) -> Bool {
        return lhs.path == rhs.path
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
    }

    /// Get display name
    var displayName: String {
        if let manufacturer = manufacturer {
            return "\(manufacturer) \(name)"
        }
        return name
    }
}
