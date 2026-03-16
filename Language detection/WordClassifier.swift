//
//  WordClassifier.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Foundation
import AppKit

struct ReplacementDecision {
    let replacement: String
    let targetInputSourceID: String
    let shouldReplace: Bool
}

/// Result when both layouts produce valid words (dual-layout ambiguity)
struct DualLayoutAmbiguity {
    let currentWord: String
    let alternativeWord: String
    let alternativeInputSourceID: String
    /// True if current layout appears to be Hebrew, false if English
    let currentIsHebrew: Bool
}

final class WordClassifier {
    private let hebrewID: String
    private let englishID: String
    private let mapper = KeyboardMapper()
    private let speller = NSSpellChecker.shared

    init(hebrewID: String, englishID: String) {
        self.hebrewID = hebrewID
        self.englishID = englishID
    }

    /// Detects if a word is valid in BOTH the current layout AND the alternative layout.
    /// Returns a DualLayoutAmbiguity if both are valid words, otherwise nil.
    func detectAmbiguity(for word: String) -> DualLayoutAmbiguity? {
        let currentAsEnglishScore = spellingScore(word, language: "en_US")
        let currentAsHebrewScore = spellingScore(word, language: "he_IL")
        
        // Map to alternative layouts
        let mappedToHebrew = mapper.usToHebrew(word.lowercased())
        let mappedToEnglish = mapper.hebrewToUS(word)
        
        let hebrewCandidateScore = spellingScore(mappedToHebrew, language: "he_IL")
        let englishCandidateScore = spellingScore(mappedToEnglish, language: "en_US")
        
        // Case 1: Current word is valid English AND mapped Hebrew is also valid
        // User typed in English layout, word is valid English, but also valid Hebrew if they meant Hebrew
        if currentAsEnglishScore >= 2 && hebrewCandidateScore >= 2 && mappedToHebrew != word {
            return DualLayoutAmbiguity(
                currentWord: word,
                alternativeWord: mappedToHebrew,
                alternativeInputSourceID: hebrewID,
                currentIsHebrew: false
            )
        }
        
        // Case 2: Current word is valid Hebrew AND mapped English is also valid
        // User typed in Hebrew layout, word is valid Hebrew, but also valid English if they meant English
        if currentAsHebrewScore >= 2 && englishCandidateScore >= 2 && mappedToEnglish != word {
            return DualLayoutAmbiguity(
                currentWord: word,
                alternativeWord: mappedToEnglish,
                alternativeInputSourceID: englishID,
                currentIsHebrew: true
            )
        }
        
        return nil
    }

    func decide(for word: String) -> ReplacementDecision? {
        // קבלת ניקוד עבור המילה כפי שהיא הוקלדה
        let currentAsEnglishScore = spellingScore(word, language: "en_US")
        let currentAsHebrewScore = spellingScore(word, language: "he_IL")

        // 1. נסה לראות אם זו הקלדה שגויה על מקלדת אנגלית (צריך להיות עברית)
        // לדוגמה: "cse,h" -> "בדקתי"
        let mappedToHebrew = mapper.usToHebrew(word.lowercased())
        let hebrewCandidateScore = spellingScore(mappedToHebrew, language: "he_IL")
        
        // הלוגיקה: אם המילה המומרת לעברית היא תקינה (score 2)
        // והמילה המקורית היא לא מילה תקינה באנגלית (score < 2)
        if hebrewCandidateScore >= 2 && currentAsEnglishScore < 2 {
             // לוודא שההמרה אכן שינתה משהו (מניעת החלפות שווא של סימנים)
             if mappedToHebrew != word {
                 return ReplacementDecision(replacement: mappedToHebrew, targetInputSourceID: hebrewID, shouldReplace: true)
             }
        }

        // 2. נסה לראות אם זו הקלדה שגויה על מקלדת עברית (צריך להיות אנגלית)
        // לדוגמה: "הקךךם" -> "hello"
        let mappedToEnglish = mapper.hebrewToUS(word)
        let englishCandidateScore = spellingScore(mappedToEnglish, language: "en_US")
        
        if englishCandidateScore >= 2 && currentAsHebrewScore < 2 {
            if mappedToEnglish != word {
                return ReplacementDecision(replacement: mappedToEnglish, targetInputSourceID: englishID, shouldReplace: true)
            }
        }

        return nil
    }

    /// 0 = unknown/bad, 1 = has a correction, 2 = already correct
    private func spellingScore(_ w: String, language: String) -> Int {
        if w.isEmpty { return 0 }
        
        // בדיקה בסיסית - סינון תווים שלא שייכים לשפה בכלל יכול לחסוך קריאות יקרות
        // אבל עדיף לתת ל-SpellChecker להחליט
        
        let range = NSRange(location: 0, length: (w as NSString).length)
        let miss = speller.checkSpelling(of: w, startingAt: 0, language: language, wrap: false, inSpellDocumentWithTag: 0, wordCount: nil)
        
        if miss.location == NSNotFound {
            return 2 // המילה תקינה לחלוטין
        }

        // אם יש הצעות לתיקון, זה ציון 1, אחרת 0
        let guesses = speller.guesses(forWordRange: miss, in: w, language: language, inSpellDocumentWithTag: 0)
        return (guesses?.isEmpty == false) ? 1 : 0
    }
}
