//
//  AppDelegate.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Cocoa
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private let appState = AppState.shared
    private var enabledCancellable: AnyCancellable?
    private weak var toggleItem: NSMenuItem?
    private var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Language Switcher")

        let menu = NSMenu()

        let toggle = NSMenuItem(title: "Enable", action: #selector(toggleEnabled), keyEquivalent: "")
        toggle.state = appState.isEnabled ? .on : .off
        toggle.target = self
        menu.addItem(toggle)
        self.toggleItem = toggle

        menu.addItem(.separator())

        let openSettings = NSMenuItem(title: "Settings…", action: #selector(openSettingsWindow), keyEquivalent: ",")
        openSettings.target = self
        menu.addItem(openSettings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu

        // Keep menu item in sync when isEnabled changes from the dashboard
        enabledCancellable = appState.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.toggleItem?.state = enabled ? .on : .off
            }

        // Capture the main SwiftUI window so we can hide/show it instead of destroying it
        DispatchQueue.main.async { [weak self] in
            self?.captureMainWindow()
        }

        appState.start()
    }

    // MARK: - Window Management

    private func captureMainWindow() {
        guard let window = NSApp.windows.first(where: { !$0.isKind(of: NSPanel.self) }) else { return }
        mainWindow = window
        window.delegate = self
    }

    /// Hide the window instead of closing it so we can show it again later.
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        NSApp.setActivationPolicy(.accessory)
        return false
    }

    @objc private func openSettingsWindow() {
        appState.selectedSidebarItem = .preferences
        showMainWindow()
    }

    private func showMainWindow() {
        // Become a regular app so the window can come to front
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Window reference lost — recapture
            captureMainWindow()
            mainWindow?.makeKeyAndOrderFront(nil)
        }
    }

    // When the last window is gone, go back to accessory (menu-bar-only) mode
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }

    // MARK: - Menu Actions

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        appState.isEnabled.toggle()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
