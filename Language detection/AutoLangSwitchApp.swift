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
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 950, height: 700)
        .handlesExternalEvents(matching: Set(arrayLiteral: "main"))
    }
}
