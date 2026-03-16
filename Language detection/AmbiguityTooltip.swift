//
//  AmbiguityTooltip.swift
//  Language detection
//
//  Created by yosef kiali on 31/01/2026.
//

import Cocoa
import ApplicationServices

/// Result struct for dual-layout ambiguity detection
struct AmbiguityResult {
    let originalWord: String
    let alternativeWord: String
    let targetInputSourceID: String
}

/// A floating tooltip panel that displays the alternative word suggestion
/// Uses native macOS appearance for seamless integration
final class AmbiguityTooltipWindow: NSPanel {
    
    private let label: NSTextField
    private var dismissTimer: Timer?
    
    static let shared = AmbiguityTooltipWindow()
    
    private init() {
        label = NSTextField(labelWithString: "")
        
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 36),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        setupWindow()
        setupContent()
    }
    
    private func setupWindow() {
        // Window behavior - doesn't steal focus, floats above other windows
        level = .floating
        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        
        // Transparent window with visual effect background
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        
        // Don't show in window lists
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }
    
    private func setupContent() {
        // Visual effect view for native macOS blur/vibrancy
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 6
        visualEffect.layer?.masksToBounds = true
        
        // Configure label - minimal styling
        label.font = NSFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .labelColor
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffect.addSubview(label)
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        
        contentView = visualEffect
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: visualEffect.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: visualEffect.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: visualEffect.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(lessThanOrEqualTo: visualEffect.trailingAnchor, constant: -8),
        ])
    }
    
    /// Shows the tooltip with the alternative word suggestion
    /// - Parameters:
    ///   - alternative: The word in the alternative layout
    ///   - nearLocation: Optional location hint (currently unused)
    ///   - timeout: Auto-dismiss timeout in seconds (default 3.0)
    func show(alternative: String, nearLocation: CGPoint? = nil, timeout: TimeInterval = 3.0) {
        // Update label
        label.stringValue = alternative
        
        // Size to fit content - minimal padding
        let textSize = label.sizeThatFits(NSSize(width: 300, height: 100))
        let windowWidth = max(40, textSize.width + 20)
        let windowHeight: CGFloat = 28
        
        // Position the tooltip
        let position = calculatePosition(windowSize: NSSize(width: windowWidth, height: windowHeight))
        
        setFrame(NSRect(
            x: position.x,
            y: position.y,
            width: windowWidth,
            height: windowHeight
        ), display: true)
        
        // Show with animation
        alphaValue = 0
        orderFrontRegardless()
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            self.animator().alphaValue = 1
        }
        
        // Set auto-dismiss timer
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    /// Calculates the position for the tooltip
    /// Tries Accessibility API first, falls back to window position, then mouse
    private func calculatePosition(windowSize: NSSize) -> NSPoint {
        // Priority 1: Try to get text cursor position via Accessibility API
        if let cursorPosition = getTextCursorPosition() {
            var position = NSPoint(
                x: cursorPosition.x - windowSize.width / 2,
                y: cursorPosition.y - windowSize.height - 2
            )
            // Keep within screen bounds
            if let screen = NSScreen.main {
                position.x = max(screen.visibleFrame.minX + 4, min(position.x, screen.visibleFrame.maxX - windowSize.width - 4))
                position.y = max(screen.visibleFrame.minY + 4, min(position.y, screen.visibleFrame.maxY - windowSize.height - 4))
            }
            return position
        }
        
        // Fallback 1: Position relative to frontmost window
        if let windowPosition = getFrontmostWindowPosition(windowSize: windowSize) {
            return windowPosition
        }
        
        // Fallback 2: Position near mouse cursor
        let mouseLocation = NSEvent.mouseLocation
        
        // Get screen bounds to ensure tooltip stays on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            
            var x = mouseLocation.x - windowSize.width / 2
            var y = mouseLocation.y - windowSize.height - 8
            
            // Keep within screen bounds
            x = max(screenFrame.minX + 4, min(x, screenFrame.maxX - windowSize.width - 4))
            y = max(screenFrame.minY + 4, min(y, screenFrame.maxY - windowSize.height - 4))
            
            return NSPoint(x: x, y: y)
        }
        
        return NSPoint(x: mouseLocation.x - windowSize.width / 2, y: mouseLocation.y - windowSize.height - 8)
    }
    
    /// Attempts to get the text cursor (caret) position using Accessibility API
    private func getTextCursorPosition() -> NSPoint? {
        // Use system-wide element (more reliable than app-specific)
        let systemWide = AXUIElementCreateSystemWide()
        
        var focusedElement: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(systemWide, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard focusResult == .success, let element = focusedElement else { return nil }
        let axElement = element as! AXUIElement
        
        // Method 1: Try selected text range bounds (most accurate for cursor position)
        if let position = getPositionFromSelectedTextRange(axElement) {
            return position
        }
        
        // Method 2: Try to find a text element in the hierarchy and get its caret position
        if let position = findTextElementAndGetCaretPosition(axElement) {
            return position
        }
        
        // Method 3: Try focused element's frame as fallback
        if let position = getPositionFromElementFrame(axElement) {
            return position
        }
        
        return nil
    }
    
    private func getPositionFromSelectedTextRange(_ element: AXUIElement) -> NSPoint? {
        var selectedRangeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextRangeAttribute as CFString, &selectedRangeValue) == .success,
              let rangeValue = selectedRangeValue else { return nil }
        
        var boundsValue: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, kAXBoundsForRangeParameterizedAttribute as CFString, rangeValue, &boundsValue) == .success,
              let bounds = boundsValue else { return nil }
        
        var rect = CGRect.zero
        guard AXValueGetValue(bounds as! AXValue, .cgRect, &rect) else { return nil }
        
        // AX coordinates are top-left origin, need to flip Y for NSWindow (bottom-left origin)
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
        let flippedY = primaryScreenHeight - rect.maxY
        
        return NSPoint(x: rect.midX, y: flippedY)
    }
    
    private func findTextElementAndGetCaretPosition(_ startElement: AXUIElement) -> NSPoint? {
        // Check if this element has text-related attributes
        var role: CFTypeRef?
        AXUIElementCopyAttributeValue(startElement, kAXRoleAttribute as CFString, &role)
        let roleString = role as? String ?? ""
        
        // If it's a text area or text field, try to get caret position
        if roleString == "AXTextArea" || roleString == "AXTextField" || roleString == "AXComboBox" {
            if let pos = getPositionFromSelectedTextRange(startElement) {
                return pos
            }
        }
        
        // Try to get children and search recursively (limited depth)
        var children: CFTypeRef?
        guard AXUIElementCopyAttributeValue(startElement, kAXChildrenAttribute as CFString, &children) == .success,
              let childArray = children as? [AXUIElement] else { return nil }
        
        for child in childArray.prefix(10) { // Limit to prevent deep recursion
            var childRole: CFTypeRef?
            AXUIElementCopyAttributeValue(child, kAXRoleAttribute as CFString, &childRole)
            let childRoleString = childRole as? String ?? ""
            
            if childRoleString == "AXTextArea" || childRoleString == "AXTextField" || childRoleString == "AXComboBox" {
                if let pos = getPositionFromSelectedTextRange(child) {
                    return pos
                }
            }
        }
        
        return nil
    }
    
    private func getPositionFromElementFrame(_ element: AXUIElement) -> NSPoint? {
        var frameValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, "AXFrame" as CFString, &frameValue) == .success,
              let frame = frameValue else { return nil }
        
        var rect = CGRect.zero
        guard AXValueGetValue(frame as! AXValue, .cgRect, &rect) else { return nil }
        
        // AX coordinates are top-left origin, need to flip Y
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
        let flippedY = primaryScreenHeight - rect.maxY
        
        return NSPoint(x: rect.midX, y: flippedY)
    }
    
    /// Gets a fallback position based on the frontmost window
    private func getFrontmostWindowPosition(windowSize: NSSize) -> NSPoint? {
        guard let focusedApp = NSWorkspace.shared.frontmostApplication else { return nil }
        
        let appElement = AXUIElementCreateApplication(focusedApp.processIdentifier)
        
        // Get the focused window
        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
              let window = focusedWindow else { return nil }
        
        // Get window position and size
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        
        guard AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &positionValue) == .success,
              AXUIElementCopyAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString, &sizeValue) == .success,
              let pos = positionValue, let size = sizeValue else { return nil }
        
        var windowOrigin = CGPoint.zero
        var windowSizeVal = CGSize.zero
        
        guard AXValueGetValue(pos as! AXValue, .cgPoint, &windowOrigin),
              AXValueGetValue(size as! AXValue, .cgSize, &windowSizeVal) else { return nil }
        
        // AX coordinates are top-left origin, need to flip Y
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? NSScreen.main?.frame.height ?? 0
        
        // Position tooltip at bottom-center of the window, just above the bottom edge
        let x = windowOrigin.x + windowSizeVal.width / 2 - windowSize.width / 2
        let flippedY = primaryScreenHeight - windowOrigin.y - windowSizeVal.height + 50
        
        return NSPoint(x: x, y: flippedY)
    }
    
    /// Dismisses the tooltip with animation
    func dismiss() {
        dismissTimer?.invalidate()
        dismissTimer = nil
        
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.orderOut(nil)
        })
    }
    
    /// Returns whether the tooltip is currently visible
    var isShowing: Bool {
        return isVisible && alphaValue > 0
    }
}
