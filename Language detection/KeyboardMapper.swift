//
//  KeyboardMapper.swift
//  Language detection
//
//  Created by yosef kiali on 23/01/2026.
//

import Foundation

class KeyboardMapper {

    private let usToHe: [Character: Character] = [
        "a":"ש", "b":"נ", "c":"ב", "d":"ג", "e":"ק", "f":"כ", "g":"ע", "h":"י", "i":"ן", "j":"ח",
        "k":"ל", "l":"ך", "m":"צ", "n":"מ", "o":"ם", "p":"פ", "q":"/", "r":"ר", "s":"ד", "t":"א",
        "u":"ו", "v":"ה", "w":"'", "x":"ס", "y":"ט", "z":"ז",
        ",": "ת",
        ".": "ץ",
        ";": "ף",
        "'": ",",
        "/": "."
    ]

    // המיפוי ההפוך צריך להיות "חכם" יותר ולקבל וריאציות
    private lazy var heToUs: [Character: Character] = {
        var inv: [Character: Character] = [:]
        
        // יצירת המיפוי הבסיסי
        for (k, v) in usToHe {
            inv[v] = k
        }
        
        // *** תיקונים ידניים לבעיית ה-w ***
        // כשלוחצים w במקלדת עברית, זה עשוי לצאת כאחד מהתווים הבאים:
        inv["׳"] = "w" // Hebrew Geresh
        inv["’"] = "w" // Right Single Quotation Mark (Smart Quote)
        inv["‘"] = "w" // Left Single Quotation Mark
        
        // תיקונים נוספים אם צריך (למשל מקש q שעושה /)
        // במקלדת עברית סטנדרטית q זה /
        
        return inv
    }()

    func usToHebrew(_ s: String) -> String {
        String(s.map { ch in
            let lower = Character(String(ch).lowercased())
            return usToHe[lower] ?? ch
        })
    }

    func hebrewToUS(_ s: String) -> String {
        String(s.map { ch in
            // כאן אנו בודקים אם יש מיפוי ישיר
            if let mapped = heToUs[ch] {
                return mapped
            }
            // ניסיון נוסף: אולי זה גרש/מרכאות שלא תפסנו?
            // במקרה הזה נשאיר את התו כמו שהוא
            return ch
        })
    }
}
