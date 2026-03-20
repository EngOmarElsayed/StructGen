//
//  StructGenApp.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI
import ServiceManagement

@main
struct StructGenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .background(TransparentTitleBarHelper())
        }
        .defaultSize(width: 950, height: 600)
        .windowToolbarStyle(.unified)
    }
}

// MARK: - Transparent Title Bar
private struct TransparentTitleBarHelper: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.titlebarAppearsTransparent = true
            window.backgroundColor = .windowBackgroundColor
            window.isMovableByWindowBackground = true
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
