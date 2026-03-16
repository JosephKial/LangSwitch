//
//  AppDelegate.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Cocoa
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let appState = AppState.shared
    private var enabledCancellable: AnyCancellable?
    private weak var toggleItem: NSMenuItem?

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

        appState.start()
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        appState.isEnabled.toggle()
    }

    @objc private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
