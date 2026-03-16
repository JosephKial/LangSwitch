//
//  MainWindowView.swift
//  Language detection
//
//  Created by yosef kiali on 25/01/2026.
//

import SwiftUI

// MARK: - Data Models

struct CorrectionRecord: Identifiable {
    let id = UUID()
    let time: Date
    let inputText: String
    let outputText: String
    let appName: String

    /// Derive a consistent color from the app name
    var appColor: Color {
        let colors: [Color] = [.blue, .orange, .green, .red, .purple, .pink, .teal, .indigo]
        let hash = appName.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return colors[hash % colors.count]
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case exceptions = "Exceptions"
    case preferences = "Preferences"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .exceptions: return "list.bullet"
        case .preferences: return "gearshape"
        }
    }
}

// MARK: - Main Window View

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $appState.selectedSidebarItem)
        } detail: {
            switch appState.selectedSidebarItem {
            case .dashboard:
                DashboardView(
                    isEnabled: $appState.isEnabled,
                    correctionsToday: appState.correctionsToday,
                    percentageChange: appState.percentageChange,
                    recentActivity: appState.corrections
                )
            case .exceptions:
                ExceptionsView()
                    .environmentObject(appState)
            case .preferences:
                PreferencesContentView()
            }
        }
        .frame(minWidth: 900, minHeight: 650)
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // App Header
            VStack(alignment: .leading, spacing: 4) {
                Text("LangSwitch")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("v2.1.0 Pro")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
            
            // Navigation Items
            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    SidebarButton(
                        item: item,
                        isSelected: selectedItem == item
                    ) {
                        selectedItem = item
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // About Button
            Button(action: {}) {
                HStack(spacing: 12) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                    Text("About")
                        .font(.system(size: 14))
                    Spacer()
                }
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .frame(width: 200)
        .background(Color(red: 0.11, green: 0.11, blue: 0.12))
    }
}

struct SidebarButton: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 16))
                Text(item.rawValue)
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
            .foregroundColor(isSelected ? .white : .gray)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dashboard View

struct DashboardView: View {
    @Binding var isEnabled: Bool
    let correctionsToday: Int
    let percentageChange: Double
    let recentActivity: [CorrectionRecord]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Header
            HStack {
                Text("Dashboard")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Notification Bell
                Button(action: {}) {
                    Image(systemName: "bell")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 12)
                
                // Profile Circle
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Status Card
                    StatusCardView(isEnabled: $isEnabled, correctionsToday: correctionsToday, percentageChange: percentageChange)
                    
                    // Recent Activity Section
                    RecentActivityView(records: recentActivity)
                    
                    // Pro Tip Card
                    ProTipCardView()
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.10))
    }
}

// MARK: - Status Card View

struct StatusCardView: View {
    @Binding var isEnabled: Bool
    let correctionsToday: Int
    let percentageChange: Double
    
    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left Section - Status
            VStack(alignment: .leading, spacing: 12) {
                // Active Badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(isEnabled ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(isEnabled ? "ACTIVE" : "PAUSED")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isEnabled ? .green : .red)
                }

                // Title and Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isEnabled ? "LangSwitch is On" : "LangSwitch is Off")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text(isEnabled
                            ? "Monitoring keystrokes to detect and correct language\nmismatches automatically."
                            : "Language detection is paused. Toggle to resume.")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                            .lineSpacing(2)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        .labelsHidden()
                        .scaleEffect(1.2)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 1)
                .padding(.vertical, 20)
            
            // Right Section - Corrections Today
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Corrections Today")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                    Spacer()
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16))
                        .foregroundColor(.purple)
                }
                
                Text("\(correctionsToday)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                if percentageChange != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: percentageChange > 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 12))
                        Text("\(percentageChange > 0 ? "+" : "")\(Int(percentageChange))% vs yesterday")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(percentageChange > 0 ? .green : .orange)
                }
            }
            .padding(24)
            .frame(width: 200)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.13, green: 0.14, blue: 0.16))
        )
    }
}

// MARK: - Recent Activity View

struct RecentActivityView: View {
    let records: [CorrectionRecord]
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View History") {
                    // Action
                }
                .font(.system(size: 13))
                .foregroundColor(.blue)
                .buttonStyle(.plain)
            }
            
            // Table
            VStack(spacing: 0) {
                // Header Row
                HStack(spacing: 0) {
                    Text("TIME")
                        .frame(width: 100, alignment: .leading)
                    Text("INPUT (EN)")
                        .frame(width: 150, alignment: .leading)
                    Text("ACTION")
                        .frame(width: 100, alignment: .center)
                    Text("OUTPUT (HE)")
                        .frame(width: 120, alignment: .trailing)
                    Text("APP")
                        .frame(width: 60, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                Divider()
                    .background(Color.gray.opacity(0.3))
                
                // Data Rows
                if records.isEmpty {
                    VStack(spacing: 8) {
                        Text("No corrections yet")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        Text("Start typing in any app — LangSwitch will auto-correct wrong-layout words.")
                            .font(.system(size: 12))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ForEach(records.prefix(20)) { record in
                        ActivityRowView(record: record, timeFormatter: timeFormatter)

                        if record.id != records.last?.id {
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.13, green: 0.14, blue: 0.16))
            )
        }
    }
}

struct ActivityRowView: View {
    let record: CorrectionRecord
    let timeFormatter: DateFormatter
    
    var body: some View {
        HStack(spacing: 0) {
            Text(timeFormatter.string(from: record.time))
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.gray)
            
            Text(record.inputText)
                .frame(width: 150, alignment: .leading)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange.opacity(0.15))
                )
            
            Image(systemName: "arrow.right")
                .frame(width: 100, alignment: .center)
                .foregroundColor(.gray)
            
            Text(record.outputText)
                .frame(width: 120, alignment: .trailing)
                .foregroundColor(.white)
            
            // App Badge
            ZStack {
                Circle()
                    .fill(record.appColor)
                    .frame(width: 28, height: 28)
                Text(record.appName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 60, alignment: .trailing)
        }
        .font(.system(size: 13))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Pro Tip Card View

struct ProTipCardView: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
            
            Text("Pro Tip")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text("You can hold")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            Text("Shift")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.2, green: 0.21, blue: 0.23))
                )
            
            Text("while typing to temporarily bypass LangSwitch correction.")
                .font(.system(size: 13))
                .foregroundColor(.gray)
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.13, green: 0.14, blue: 0.16))
        )
    }
}

// MARK: - Placeholder Views

struct ExceptionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var newWord: String = ""
    @State private var newApp: String = ""
    @State private var selectedTab: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Exceptions")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 8)

            Text("Configure apps and words to exclude from automatic switching.")
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Excluded Words").tag(0)
                Text("Excluded Apps").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)

            if selectedTab == 0 {
                excludedWordsSection
            } else {
                excludedAppsSection
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.09, blue: 0.10))
    }

    private var excludedWordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Add word
            HStack(spacing: 8) {
                TextField("Add a word to exclude...", text: $newWord)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let trimmed = newWord.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty,
                          !appState.excludedWords.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
                    else { return }
                    appState.excludedWords.append(trimmed)
                    newWord = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newWord.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)

            // List
            if appState.excludedWords.isEmpty {
                VStack(spacing: 8) {
                    Text("No excluded words")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Words added here will never be auto-corrected.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(appState.excludedWords, id: \.self) { word in
                            HStack {
                                Text(word)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    appState.excludedWords.removeAll { $0 == word }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            Divider().background(Color.gray.opacity(0.2))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.13, green: 0.14, blue: 0.16))
                    )
                }
                .padding(.horizontal, 32)
            }
        }
    }

    private var excludedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Add app by bundle ID
            HStack(spacing: 8) {
                TextField("App bundle ID (e.g. com.apple.Notes)", text: $newApp)
                    .textFieldStyle(.roundedBorder)
                Button("Add") {
                    let trimmed = newApp.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty, !appState.excludedApps.contains(trimmed) else { return }
                    appState.excludedApps.append(trimmed)
                    newApp = ""
                }
                .buttonStyle(.borderedProminent)
                .disabled(newApp.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 32)

            // Running apps picker
            RunningAppsPickerView()
                .environmentObject(appState)
                .padding(.horizontal, 32)

            // List
            if appState.excludedApps.isEmpty {
                VStack(spacing: 8) {
                    Text("No excluded apps")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    Text("Apps added here will not trigger auto-correction.")
                        .font(.system(size: 12))
                        .foregroundColor(.gray.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(appState.excludedApps, id: \.self) { bundleID in
                            HStack {
                                Text(bundleID)
                                    .foregroundColor(.white)
                                    .font(.system(size: 13, design: .monospaced))
                                Spacer()
                                Button(action: {
                                    appState.excludedApps.removeAll { $0 == bundleID }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.8))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)

                            Divider().background(Color.gray.opacity(0.2))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 0.13, green: 0.14, blue: 0.16))
                    )
                }
                .padding(.horizontal, 32)
            }
        }
    }
}

/// Displays running apps for quick exclusion
struct RunningAppsPickerView: View {
    @EnvironmentObject var appState: AppState

    private var runningApps: [(name: String, bundleID: String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let name = app.localizedName, let bid = app.bundleIdentifier else { return nil }
                return (name, bid)
            }
            .sorted { $0.name < $1.name }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quick add from running apps:")
                .font(.system(size: 12))
                .foregroundColor(.gray)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(runningApps, id: \.bundleID) { app in
                        let isExcluded = appState.excludedApps.contains(app.bundleID)
                        Button(action: {
                            if isExcluded {
                                appState.excludedApps.removeAll { $0 == app.bundleID }
                            } else {
                                appState.excludedApps.append(app.bundleID)
                            }
                        }) {
                            Text(app.name)
                                .font(.system(size: 12))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isExcluded ? Color.red.opacity(0.3) : Color(red: 0.2, green: 0.21, blue: 0.23))
                                )
                                .foregroundColor(isExcluded ? .red : .white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct PreferencesContentView: View {
    @AppStorage("hebrewInputSourceID") private var hebrewID: String = "com.apple.keylayout.Hebrew"
    @AppStorage("englishInputSourceID") private var englishID: String = "com.apple.keylayout.ABC"
    @AppStorage("minWordLength") private var minWordLength: Int = 2
    @AppStorage("dualLayoutAmbiguityEnabled") private var dualLayoutAmbiguityEnabled: Bool = true
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Preferences")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 20) {
                    // Input Sources
                    preferencesCard(title: "Input Sources", icon: "keyboard") {
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hebrew Input Source ID")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                TextField("com.apple.keylayout.Hebrew", text: $hebrewID)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 13, design: .monospaced))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text("English Input Source ID")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                TextField("com.apple.keylayout.ABC", text: $englishID)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.system(size: 13, design: .monospaced))
                            }
                            Text("If switching doesn't work, verify these IDs exist on your system.")
                                .font(.system(size: 11))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }

                    // Behavior
                    preferencesCard(title: "Behavior", icon: "gearshape.2") {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Minimum word length")
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(minWordLength) characters", value: $minWordLength, in: 1...20)
                                    .foregroundColor(.gray)
                            }

                            Divider().background(Color.gray.opacity(0.3))

                            VStack(alignment: .leading, spacing: 6) {
                                Toggle("Dual-Layout Ambiguity Detection", isOn: $dualLayoutAmbiguityEnabled)
                                    .foregroundColor(.white)
                                if dualLayoutAmbiguityEnabled {
                                    Text("When a word is valid in both layouts, a tooltip appears. Press Tab to switch.")
                                        .font(.system(size: 11))
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                            }
                        }
                    }

                    // General
                    preferencesCard(title: "General", icon: "laptopcomputer") {
                        Toggle("Launch at Login", isOn: $launchAtLogin)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.09, blue: 0.10))
    }

    private func preferencesCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.13, green: 0.14, blue: 0.16))
        )
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
}
