//
//  MenuBarController.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import AppKit

@MainActor
final class MenuBarController {
    static let shared = MenuBarController()
    
    private var statusItem: NSStatusItem?
    
    private init() {}
    
    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "greaterthan", accessibilityDescription: "Quick Convert")
            button.action = #selector(menuBarButtonTapped)
            button.target = self
        }
    }
    
    @objc private func menuBarButtonTapped() {
        QuickActionPanelController.shared.toggle()
    }
}
