//
//  AppDelegate.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let engine = TypingEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.title = ""
       
        statusItem.button?.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Language Switcher")

        let menu = NSMenu()

        let toggleItem = NSMenuItem(title: "Enable", action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.state = engine.isEnabled ? .on : .off
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let openSettings = NSMenuItem(title: "Settings…", action: #selector(openSettingsWindow), keyEquivalent: ",")
        openSettings.target = self
        menu.addItem(openSettings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu

        engine.start()
    }

    @objc private func toggleEnabled(_ sender: NSMenuItem) {
        engine.isEnabled.toggle()
        sender.state = engine.isEnabled ? .on : .off
    }

    @objc private func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
