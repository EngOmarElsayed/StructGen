//
//  AppDelegate.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import Foundation
import ServiceManagement
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        try? SMAppService.mainApp.register()
        MenuBarController.shared.setup()
        registerHotKey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        GlobalHotkeyManager.shared.unregister()
    }

    private func registerHotKey() {
        GlobalHotkeyManager.shared.onTrigger = {
            DispatchQueue.main.async {
                NSApp.activate(ignoringOtherApps: true)
                QuickActionPanelController.shared.toggle()
            }
        }
        GlobalHotkeyManager.shared.register()
    }
}
