//
//  TypingEngine.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Cocoa
import Carbon

final class TypingEngine {
    var isEnabled: Bool = true

    private var hebrewID: String {
        UserDefaults.standard.string(forKey: "hebrewInputSourceID") ?? "com.apple.keylayout.Hebrew"
    }

    private var englishID: String {
        UserDefaults.standard.string(forKey: "englishInputSourceID") ?? "com.apple.keylayout.ABC"
    }

    private var minWordLength: Int {
        let val = UserDefaults.standard.integer(forKey: "minWordLength")
        return val == 0 ? 2 : val
    }
    
    private var dualLayoutAmbiguityEnabled: Bool {
        // Default to true if not set
        if UserDefaults.standard.object(forKey: "dualLayoutAmbiguityEnabled") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "dualLayoutAmbiguityEnabled")
    }

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var buffer: String = ""
    private var isInjecting: Bool = false
    
    // Dual-layout ambiguity state
    private var pendingAmbiguity: DualLayoutAmbiguity?
    private var pendingWordLength: Int = 0

    func start() {
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            let engine = Unmanaged<TypingEngine>.fromOpaque(refcon!).takeUnretainedValue()
            return engine.handle(proxy: proxy, type: type, event: event)
        }

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: refcon
        )

        guard let eventTap else {
            NSLog("Failed to create event tap. Enable Input Monitoring permission.")
            return
        }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }

    private func isSecureInputEnabled() -> Bool {
        return IsSecureEventInputEnabled()
    }
    
    private func handle(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if !isEnabled { return Unmanaged.passUnretained(event) }
        
        if isInjecting { return Unmanaged.passUnretained(event) }
        if isSecureInputEnabled() {
                buffer = ""
                return Unmanaged.passUnretained(event)
            }
        
        guard type == .keyDown else { return Unmanaged.passUnretained(event) }

        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags

        // התעלמות מפקודות (Cmd, Ctrl, Alt)
        if flags.contains(.maskCommand) || flags.contains(.maskControl) || flags.contains(.maskAlternate) {
            buffer = ""
            return Unmanaged.passUnretained(event)
        }

        if keyCode == KeyCodes.delete {
            if !buffer.isEmpty { buffer.removeLast() }
            dismissAmbiguityTooltip()
            return Unmanaged.passUnretained(event)
        }

        // Check for Tab key with pending ambiguity - this triggers the replacement
        if keyCode == KeyCodes.tab && pendingAmbiguity != nil {
            handleAmbiguityAcceptance()
            return nil  // Consume the Tab event
        }

        // טריגרים לבדיקה והחלפה
        if keyCode == KeyCodes.space || keyCode == KeyCodes.tab || keyCode == KeyCodes.returnKey {
            let boundary = keyCode
            processWordOnBoundary(boundaryKey: boundary)
            buffer = ""
            return Unmanaged.passUnretained(event)
        }

        if let s = event.stringValue, s.count == 1 {
            let ch = s.first!
            // כאן השינוי: אנו מאפשרים כניסה ל-buffer גם לתווים שנראים כמו פיסוק
            // כי ייתכן שהם חלק ממילה בשפה השנייה (למשל פסיק הוא 'ת')
            if CharacterSets.potentialWordChars.contains(ch) {
                buffer.append(ch)
                // Dismiss tooltip on any new character typed
                dismissAmbiguityTooltip()
            } else {
                buffer = ""
                dismissAmbiguityTooltip()
            }
        }

        return Unmanaged.passUnretained(event)
    }
    
    // MARK: - Dual-Layout Ambiguity Handling
    
    private func handleAmbiguityAcceptance() {
        guard let ambiguity = pendingAmbiguity else { return }
        
        isInjecting = true
        defer { 
            isInjecting = false
            dismissAmbiguityTooltip()
        }
        
        // Delete the original word (including the space that was typed after it)
        postBackspaces(count: pendingWordLength + 1)
        
        // Switch to the alternative input source
        InputSourceSwitcher.select(inputSourceID: ambiguity.alternativeInputSourceID)
        
        // Type the alternative word followed by a space
        postString(ambiguity.alternativeWord)
        postKey(KeyCodes.space)
    }
    
    private func dismissAmbiguityTooltip() {
        if pendingAmbiguity != nil {
            pendingAmbiguity = nil
            pendingWordLength = 0
            DispatchQueue.main.async {
                AmbiguityTooltipWindow.shared.dismiss()
            }
        }
    }
    
    private func showAmbiguityTooltip(for ambiguity: DualLayoutAmbiguity, wordLength: Int) {
        pendingAmbiguity = ambiguity
        pendingWordLength = wordLength
        DispatchQueue.main.async {
            AmbiguityTooltipWindow.shared.show(alternative: ambiguity.alternativeWord)
        }
    }

    private func processWordOnBoundary(boundaryKey: CGKeyCode) {
        let word = buffer
        guard word.count >= minWordLength else { return }

        let classifier = WordClassifier(hebrewID: hebrewID, englishID: englishID)
        
        // First, check for dual-layout ambiguity (if feature is enabled)
        if dualLayoutAmbiguityEnabled {
            if let ambiguity = classifier.detectAmbiguity(for: word) {
                // Word is valid in both layouts - show tooltip and wait for user decision
                showAmbiguityTooltip(for: ambiguity, wordLength: word.count)
                return  // Don't auto-replace, let user decide with Tab
            }
        }

        // No ambiguity - proceed with standard auto-correction logic
        guard let decision = classifier.decide(for: word) else { return }
        guard decision.shouldReplace else { return }

        isInjecting = true
        defer { isInjecting = false }

        // מחיקת המילה המקורית
        postBackspaces(count: word.count)

        // החלפת שפה
        InputSourceSwitcher.select(inputSourceID: decision.targetInputSourceID)

        // הקלדת המילה החדשה
        postString(decision.replacement)
        
    }

    private func postBackspaces(count: Int) {
        guard count > 0 else { return }
        for _ in 0..<count {
            postKey(KeyCodes.delete)
        }
    }

    private func postKey(_ keyCode: CGKeyCode) {
        guard let src = CGEventSource(stateID: .combinedSessionState) else { return }
        let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true)
        let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false)
        down?.post(tap: .cgAnnotatedSessionEventTap)
        up?.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func postString(_ string: String) {
        guard let src = CGEventSource(stateID: .combinedSessionState) else { return }
        for scalar in string.unicodeScalars {
            let down = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: true)
            down?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [UInt16(scalar.value)])
            let up = CGEvent(keyboardEventSource: src, virtualKey: 0, keyDown: false)
            up?.keyboardSetUnicodeString(stringLength: 1, unicodeString: [UInt16(scalar.value)])
            down?.post(tap: .cgAnnotatedSessionEventTap)
            up?.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}

private enum KeyCodes {
    static let delete: CGKeyCode = 51
    static let space: CGKeyCode = 49
    static let tab: CGKeyCode = 48
    static let returnKey: CGKeyCode = 36
}

private enum CharacterSets {
    static let potentialWordChars: Set<Character> = {
        var s = Set<Character>()
        // הוספת גרש עברי (׳) ומרכאות חכמות (’ ו-‘) לרשימת התווים המותרים
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'’-.,;/׳’‘"
        chars.forEach { s.insert($0) }
        
        // אותיות עבריות: הרחבת הטווח לכלול גם סופיות, גרש וגרשיים (0x05F4)
        // הטווח 0590 עד 05FF מכסה את כל הניקוד והסימנים העבריים, אך בטוח לקחת:
        for v in 0x05D0...0x05F4 {
            if let scalar = UnicodeScalar(v) {
                s.insert(Character(scalar))
            }
        }
        return s
    }()
}

private extension CGEvent {
    var stringValue: String? {
        guard let ns = self.keyboardGetUnicodeString() else { return nil }
        return ns
    }

    func keyboardGetUnicodeString() -> String? {
        var length: Int = 0
        self.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
        guard length > 0 else { return "" }
        var buffer = [UniChar](repeating: 0, count: length)
        self.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &buffer)
        return String(utf16CodeUnits: buffer, count: length)
    }
}
