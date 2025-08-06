import Foundation
import AppKit
import Carbon

// MARK: - Keyboard Shortcut Manager
class KeyboardShortcutManager: ObservableObject {
    private var registeredHotKeys: [EventHotKeyRef] = []
    private var hotKeyIDs: [String: UInt32] = [:]
    weak var delegate: KeyboardShortcutManagerDelegate?
    
    init() {
        // Set up base hot key IDs
        hotKeyIDs["startPause"] = 1
        hotKeyIDs["reset"] = 2
        hotKeyIDs["showStatistics"] = 3
    }
    
    deinit {
        unregisterAllHotKeys()
    }
    
    // MARK: - Hot Key Registration
    func registerHotKeys(shortcuts: [(action: String, modifiers: [String], key: String, isEnabled: Bool)]) {
        // Unregister existing hot keys first
        unregisterAllHotKeys()
        
        for shortcut in shortcuts where shortcut.isEnabled {
            registerHotKey(shortcut)
        }
    }
    
    private func registerHotKey(_ shortcut: (action: String, modifiers: [String], key: String, isEnabled: Bool)) {
        guard let keyCode = keyCodeForString(shortcut.key) else {
            return
        }
        
        let modifierFlags = carbonModifierFlags(from: shortcut.modifiers)
        let hotKeyID = hotKeyIDs[shortcut.action] ?? 0
        
        var hotKeyRef: EventHotKeyRef?
        
        // Install event handler if not already installed
        installEventHandler()
        
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifierFlags),
            EventHotKeyID(signature: fourCharCodeFrom("PMDR"), id: hotKeyID),
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let hotKey = hotKeyRef {
            registeredHotKeys.append(hotKey)
        } else {
        }
    }
    
    private func formatShortcut(_ shortcut: (action: String, modifiers: [String], key: String, isEnabled: Bool)) -> String {
        var result = ""
        if shortcut.modifiers.contains("cmd") { result += "⌘" }
        if shortcut.modifiers.contains("shift") { result += "⇧" }
        if shortcut.modifiers.contains("option") { result += "⌥" }
        if shortcut.modifiers.contains("control") { result += "⌃" }
        result += shortcut.key.uppercased()
        return result
    }
    
    private func unregisterAllHotKeys() {
        for hotKey in registeredHotKeys {
            UnregisterEventHotKey(hotKey)
        }
        registeredHotKeys.removeAll()
    }
    
    private var isEventHandlerInstalled = false
    
    // MARK: - Event Handling
    private func installEventHandler() {
        // Only install once
        guard !isEventHandlerInstalled else { return }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            KeyboardShortcutManager.hotKeyHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            nil
        )
        
        isEventHandlerInstalled = true
    }
    
    private static let hotKeyHandler: EventHandlerProcPtr = { (nextHandler, theEvent, userData) in
        guard let userData = userData else { return OSStatus(eventNotHandledErr) }
        
        let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(userData).takeUnretainedValue()
        
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            theEvent,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        
        guard status == noErr else { return OSStatus(eventNotHandledErr) }
        
        // Find the action for this hot key ID
        for (actionString, id) in manager.hotKeyIDs {
            if id == hotKeyID.id {
                DispatchQueue.main.async {
                    manager.delegate?.keyboardShortcutTriggered(action: actionString)
                }
                return noErr
            }
        }
        
        return OSStatus(eventNotHandledErr)
    }
    
    // MARK: - Helper Methods
    private func keyCodeForString(_ key: String) -> Int? {
        let keyMap: [String: Int] = [
            "A": 0, "S": 1, "D": 2, "F": 3, "H": 4, "G": 5, "Z": 6, "X": 7, "C": 8, "V": 9,
            "B": 11, "Q": 12, "W": 13, "E": 14, "R": 15, "Y": 16, "T": 17, "1": 18, "2": 19,
            "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28,
            "0": 29, "]": 30, "O": 31, "U": 32, "[": 33, "I": 34, "P": 35, "L": 37, "J": 38,
            "'": 39, "K": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "N": 45, "M": 46, ".": 47,
            "`": 50, "SPACE": 49, "DELETE": 51, "ESCAPE": 53, "RETURN": 36, "TAB": 48
        ]
        
        return keyMap[key.uppercased()]
    }
    
    private func carbonModifierFlags(from modifiers: [String]) -> Int {
        var flags = 0
        
        for modifier in modifiers {
            switch modifier.lowercased() {
            case "cmd", "command":
                flags |= cmdKey
            case "shift":
                flags |= shiftKey
            case "option", "alt":
                flags |= optionKey
            case "control", "ctrl":
                flags |= controlKey
            default:
                break
            }
        }
        
        return flags
    }
    
    private func fourCharCodeFrom(_ string: String) -> FourCharCode {
        let utf8 = string.utf8
        var result: FourCharCode = 0
        for (i, byte) in utf8.enumerated() {
            if i >= 4 { break }
            result = result << 8 + FourCharCode(byte)
        }
        return result
    }
}

// MARK: - Delegate Protocol
protocol KeyboardShortcutManagerDelegate: AnyObject {
    func keyboardShortcutTriggered(action: String)
}