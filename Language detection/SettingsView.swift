//
//  SettingsView.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("hebrewInputSourceID") private var hebrewID: String = "com.apple.keylayout.Hebrew"
    @AppStorage("englishInputSourceID") private var englishID: String = "com.apple.keylayout.ABC"
    @AppStorage("minWordLength") private var minWordLength: Int = 2
    @AppStorage("dualLayoutAmbiguityEnabled") private var dualLayoutAmbiguityEnabled: Bool = true

    var body: some View {
        Form {
            Section("Input source IDs") {
                TextField("Hebrew input source ID", text: $hebrewID)
                TextField("English input source ID", text: $englishID)
            }

            Section("Behavior") {
                Stepper("Minimum word length: \(minWordLength)", value: $minWordLength, in: 1...20)
                
                Toggle("Dual-Layout Ambiguity Detection", isOn: $dualLayoutAmbiguityEnabled)
                
                if dualLayoutAmbiguityEnabled {
                    Text("When a word is valid in both layouts, a tooltip will appear. Press Tab to switch to the alternative.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Notes") {
                Text("If switching doesn't work, verify the IDs exist on your system.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 520)
    }
}
