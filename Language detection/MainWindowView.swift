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
    @State private var selectedItem: SidebarItem = .dashboard

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedItem)
        } detail: {
            switch selectedItem {
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
    var body: some View {
        VStack {
            Text("Exceptions")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text("Configure apps and words to exclude from automatic switching")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.09, blue: 0.10))
    }
}

struct PreferencesContentView: View {
    var body: some View {
        VStack {
            Text("Preferences")
                .font(.largeTitle)
                .foregroundColor(.white)
            Text("Customize LangSwitch behavior and settings")
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.09, blue: 0.10))
    }
}

// MARK: - Preview

#Preview {
    MainWindowView()
}
