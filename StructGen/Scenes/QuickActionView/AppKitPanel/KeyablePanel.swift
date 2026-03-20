//
//  KeyablePanel.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI
import AppKit

private class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

// MARK: - Quick Action Panel Controller
@MainActor
final class QuickActionPanelController {
    static let shared = QuickActionPanelController()

    private var panel: NSPanel?
    private init() {}

    func toggle() {
        if let panel, panel.isVisible {
            panel.close()
            self.panel = nil
            return
        }
        show()
    }

    func show() {
        if let panel, panel.isVisible {
            panel.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(rootView: QuickActionView(onDismiss: { [weak self] in
            self?.panel?.close()
            self?.panel = nil
        }))
        hostingView.layer?.cornerRadius = 8

        let contentRect = NSRect(x: 0, y: 0, width: 700, height: 450)
        let panel = KeyablePanel(
            contentRect: contentRect,
            styleMask: [.fullSizeContentView, .nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.title = "Quick Convert"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .floating
        panel.becomesKeyOnlyIfNeeded = false
        panel.contentView = hostingView
        panel.center()
        panel.makeKeyAndOrderFront(nil)

        // Ensure the panel can receive keyboard input
        NSApp.activate(ignoringOtherApps: true)

        self.panel = panel
    }

    func dismiss() {
        panel?.close()
        panel = nil
    }
}
