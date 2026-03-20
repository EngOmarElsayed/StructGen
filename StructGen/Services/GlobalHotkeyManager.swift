//
//  GlobalHotkeyManager.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import AppKit
import Carbon.HIToolbox

/// Registers a system-wide hotkey (⌘⇧G) that works even when the app is not active.
/// Uses the Carbon RegisterEventHotKey API for true global interception.
@MainActor
final class GlobalHotkeyManager: Sendable {
    static let shared = GlobalHotkeyManager()

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    nonisolated(unsafe) var onTrigger: (@Sendable () -> Void)?

    private init() {}

    func register() {
        // ⌘⇧G  →  keyCode 5 = 'g', modifiers = cmdKey + shiftKey
        let hotkeyID = EventHotKeyID(signature: fourCharCode("SGQC"), id: 1)
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_G)

        // Install a Carbon event handler for hotkey events
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                manager.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        guard status == noErr else { return }

        RegisterEventHotKey(keyCode, modifiers, hotkeyID, GetApplicationEventTarget(), 0, &hotkeyRef)
    }

    func unregister() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }

    private func fourCharCode(_ string: String) -> OSType {
        var result: OSType = 0
        for char in string.utf8.prefix(4) {
            result = (result << 8) | OSType(char)
        }
        return result
    }
}
