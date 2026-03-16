//
//  AppState.swift
//  Language detection
//
//  Created by Claude on 16/03/2026.
//

import Foundation
import Combine

/// Shared observable state that bridges the TypingEngine with the SwiftUI UI.
final class AppState: ObservableObject {
    static let shared = AppState()

    // MARK: - Published State

    @Published var isEnabled: Bool = true {
        didSet { engine.isEnabled = isEnabled }
    }

    @Published var selectedSidebarItem: SidebarItem = .dashboard

    @Published var corrections: [CorrectionRecord] = []

    /// Corrections made today
    var correctionsToday: Int {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return corrections.filter { $0.time >= startOfDay }.count
    }

    /// Corrections made yesterday (for percentage comparison)
    var correctionsYesterday: Int {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        guard let startOfYesterday = cal.date(byAdding: .day, value: -1, to: startOfToday) else { return 0 }
        return corrections.filter { $0.time >= startOfYesterday && $0.time < startOfToday }.count
    }

    /// Percentage change vs yesterday
    var percentageChange: Double {
        guard correctionsYesterday > 0 else { return 0 }
        return Double(correctionsToday - correctionsYesterday) / Double(correctionsYesterday) * 100
    }

    // MARK: - Exceptions

    @Published var excludedApps: [String] = [] {
        didSet { save() }
    }

    @Published var excludedWords: [String] = [] {
        didSet { save() }
    }

    // MARK: - Engine

    let engine = TypingEngine()

    private let persistenceURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("LangSwitch", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private init() {
        load()
        loadCorrections()
        engine.isEnabled = isEnabled
        engine.onCorrection = { [weak self] record in
            DispatchQueue.main.async {
                self?.corrections.insert(record, at: 0)
                self?.persistCorrections()
            }
        }
        engine.shouldSkipApp = { [weak self] bundleID in
            self?.excludedApps.contains(bundleID) ?? false
        }
        engine.shouldSkipWord = { [weak self] word in
            self?.excludedWords.contains(where: { $0.lowercased() == word.lowercased() }) ?? false
        }
    }

    func start() {
        engine.start()
    }

    // MARK: - Persistence

    private func save() {
        let data: [String: Any] = [
            "excludedApps": excludedApps,
            "excludedWords": excludedWords,
        ]
        let url = persistenceURL.appendingPathComponent("state.plist")
        try? (data as NSDictionary).write(to: url)
    }

    private func load() {
        let url = persistenceURL.appendingPathComponent("state.plist")
        guard let dict = NSDictionary(contentsOf: url) as? [String: Any] else { return }
        excludedApps = dict["excludedApps"] as? [String] ?? []
        excludedWords = dict["excludedWords"] as? [String] ?? []
    }

    private func persistCorrections() {
        // Keep only last 7 days of corrections
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        corrections = corrections.filter { $0.time >= cutoff }

        let records = corrections.map { record -> [String: String] in
            [
                "inputText": record.inputText,
                "outputText": record.outputText,
                "appName": record.appName,
                "time": ISO8601DateFormatter().string(from: record.time),
            ]
        }
        let url = persistenceURL.appendingPathComponent("corrections.plist")
        try? (records as NSArray).write(to: url)
    }

    private func loadCorrections() {
        let url = persistenceURL.appendingPathComponent("corrections.plist")
        guard let array = NSArray(contentsOf: url) as? [[String: String]] else { return }
        let formatter = ISO8601DateFormatter()
        corrections = array.compactMap { dict in
            guard let input = dict["inputText"],
                  let output = dict["outputText"],
                  let app = dict["appName"],
                  let timeStr = dict["time"],
                  let time = formatter.date(from: timeStr) else { return nil }
            return CorrectionRecord(time: time, inputText: input, outputText: output, appName: app)
        }
    }
}
