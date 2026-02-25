//
//  ClipboardManager.swift
//  MoPort
//
//  Clipboard management
//

import Cocoa

class ClipboardManager {
    /// Copy text to system clipboard
    static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Read text from clipboard
    static func read() -> String? {
        let pasteboard = NSPasteboard.general
        return pasteboard.string(forType: .string)
    }
}
