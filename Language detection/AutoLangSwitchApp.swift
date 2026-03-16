//
//  AutoLangSwitchApp.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import SwiftUI

@main
struct AutoLangSwitchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 950, height: 700)
        
        
        Settings {
            SettingsView()
        }
    }
}
