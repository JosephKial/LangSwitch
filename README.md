# Language Detection (AutoLangSwitch)

A macOS menu bar app that automatically detects and corrects keyboard layout mistakes when typing in Hebrew or English.

## Purpose

When typing in a bilingual environment (Hebrew/English), it's common to accidentally type in the wrong keyboard layout. This app monitors your keystrokes and:

1. **Auto-corrects wrong layout**: If you type "cse,h" (meant to be Hebrew), it detects this isn't a valid English word but maps to "בדיקה" in Hebrew — automatically replacing it and switching the input source.

2. **Dual-Layout Ambiguity Detection**: When a word is valid in *both* layouts (e.g., "car" in English maps to "בשר" in Hebrew), a tooltip appears below the cursor. Press **Tab** to switch to the alternative, or keep typing to dismiss.

## Requirements

- macOS 13.0+
- Accessibility permission (System Settings → Privacy & Security → Accessibility)
- Input Monitoring permission

## Project Structure

```
Language detection/
├── AutoLangSwitchApp.swift      # App entry point (@main)
├── AppDelegate.swift            # Menu bar status item & engine lifecycle
├── TypingEngine.swift           # Core keystroke monitoring via CGEventTap
├── WordClassifier.swift         # Language detection & spell checking logic
├── KeyboardMapper.swift         # US ↔ Hebrew character mapping
├── InputSourceSwitcher.swift    # macOS input source switching (TIS API)
├── AmbiguityTooltip.swift       # Floating tooltip for dual-layout suggestions
├── SettingsView.swift           # SwiftUI settings panel
├── MainWindowView.swift         # Main window placeholder
└── Assets.xcassets/             # App icons and colors
```

## Key Components

### TypingEngine
- Creates a `CGEventTap` to intercept all keyboard input globally
- Maintains a buffer of typed characters
- Triggers word processing on Space, Tab, or Return
- Handles Tab key interception for ambiguity acceptance

### WordClassifier
- Uses `NSSpellChecker` to validate words in English (`en_US`) and Hebrew (`he_IL`)
- `decide(for:)` — determines if a word should be auto-replaced
- `detectAmbiguity(for:)` — checks if word is valid in both layouts

### KeyboardMapper
- Character-level mapping between US QWERTY and Hebrew keyboard layouts
- `usToHebrew(_:)` — converts English keystrokes to Hebrew characters
- `hebrewToUS(_:)` — converts Hebrew keystrokes to English characters

### AmbiguityTooltip
- Non-activating `NSPanel` that doesn't steal focus
- Uses native macOS vibrancy (`NSVisualEffectView`)
- Positions below text cursor via Accessibility API (falls back to mouse position)
- Auto-dismisses after 3 seconds

## Settings

Access via menu bar → Settings (⌘,):

| Setting | Description |
|---------|-------------|
| Hebrew Input Source ID | e.g., `com.apple.keylayout.Hebrew` |
| English Input Source ID | e.g., `com.apple.keylayout.ABC` |
| Minimum Word Length | Words shorter than this are ignored (default: 2) |
| Dual-Layout Ambiguity | Enable/disable the tooltip feature |

## How It Works

```
User types → CGEventTap captures keystrokes → Buffer accumulates
    ↓
Word boundary (Space/Tab/Return) detected
    ↓
WordClassifier analyzes the word:
    ├─ Invalid in current layout, valid in alternative → Auto-replace
    ├─ Valid in BOTH layouts → Show tooltip, wait for Tab
    └─ Valid only in current layout → Do nothing
```

## Installation & Resolving the "Damaged App" Warning

Since LangSwitch is a free, open-source project and is not signed with a paid Apple Developer certificate, macOS Gatekeeper will flag it. When you try to open it for the first time, macOS might warn that the app is from an "unidentified developer" or even claim the file is "damaged and should be moved to the Trash". 

This is standard macOS behavior for unsigned apps downloaded from the internet. Here is how to bypass it safely:

**Method 1: The Context Menu (Works on some macOS versions)**
1. Extract the downloaded ZIP and move `LangSwitch.app` into your `Applications` folder.
2. **Do not double-click** the app. Instead, **Right-click** (or Control-click) it.
3. Select **Open** from the menu.
4. Click **Open** again in the security prompt. You only need to do this once.

**Method 2: Terminal (Recommended & Foolproof)**
If Method 1 fails and macOS stubbornly insists the app is damaged, you need to strip the Apple quarantine attribute that was added when you downloaded the file.
1. Ensure `LangSwitch.app` is inside your `Applications` folder.
2. Open the **Terminal** app.
3. Paste the following command and press Enter:
   ```bash
   xattr -cr /Applications/LangSwitch.app
4. You can now launch LangSwitch normally like any other app.
