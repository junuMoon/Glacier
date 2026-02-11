import AppKit

private nonisolated func requestAccessibilityIfNeeded() {
    if !AXIsProcessTrusted() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
}

@MainActor
final class GlacierController {

    // MARK: - State

    private var isHidden = true

    // MARK: - NSStatusItems

    private let glacierIcon: NSStatusItem
    private let separator: NSStatusItem

    // MARK: - Event Monitors

    private var globalMonitor: Any?
    private var localMonitor: Any?

    // MARK: - Init

    init() {
        // Set preferred positions BEFORE creating status items
        // so macOS places them in the correct order.
        // Position 0 = rightmost, 1 = just to its left.
        let ud = UserDefaults.standard
        if ud.object(forKey: "NSStatusItem Preferred Position GlacierIcon") == nil {
            ud.set(0, forKey: "NSStatusItem Preferred Position GlacierIcon")
        }
        if ud.object(forKey: "NSStatusItem Preferred Position GlacierSep") == nil {
            ud.set(1, forKey: "NSStatusItem Preferred Position GlacierSep")
        }

        glacierIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        glacierIcon.autosaveName = "GlacierIcon"

        separator = NSStatusBar.system.statusItem(withLength: 0)
        separator.autosaveName = "GlacierSep"

        if let button = glacierIcon.button {
            let config = NSImage.SymbolConfiguration(pointSize: 6, weight: .regular)
            button.image = NSImage(
                systemSymbolName: "circle.fill",
                accessibilityDescription: "Glacier"
            )?.withSymbolConfiguration(config)
            button.target = self
            button.action = #selector(iconClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        separator.button?.cell?.isEnabled = false

        if !AXIsProcessTrusted() && !UserDefaults.standard.bool(forKey: "AccessibilityPrompted") {
            UserDefaults.standard.set(true, forKey: "AccessibilityPrompted")
            requestAccessibilityIfNeeded()
        }

        hide()
    }

    // MARK: - Toggle

    private func toggle() {
        if isHidden { show() } else { hide() }
    }

    private func show() {
        isHidden = false
        separator.length = NSStatusItem.variableLength
        startEventMonitors()
    }

    private func hide() {
        isHidden = true
        let ud = UserDefaults.standard
        let iconPos = ud.double(forKey: "NSStatusItem Preferred Position GlacierIcon")
        let newSepPos = iconPos + 1
        ud.set(newSepPos, forKey: "NSStatusItem Preferred Position GlacierSep")

        // isVisible 토글로 macOS에 위치 재계산 강제
        // isVisible=false 시 macOS가 preferredPosition을 삭제하므로 복원 필요
        separator.isVisible = false
        ud.set(newSepPos, forKey: "NSStatusItem Preferred Position GlacierSep")
        separator.isVisible = true

        separator.length = 10_000
        stopEventMonitors()
    }

    // MARK: - Click Handling

    @objc private func iconClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            toggle()
        }
    }

    // MARK: - Context Menu

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(
            title: "Quit Glacier",
            action: #selector(NSApp.terminate(_:)),
            keyEquivalent: "q"
        ))
        if let button = glacierIcon.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 5), in: button)
        }
    }

    // MARK: - Event Monitors

    private func startEventMonitors() {
        stopEventMonitors()
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            MainActor.assumeIsolated {
                self?.hide()
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            if event.window?.className.contains("NSStatusBarWindow") == false {
                MainActor.assumeIsolated {
                    self?.hide()
                }
            }
            return event
        }
    }

    private func stopEventMonitors() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
        globalMonitor = nil
        localMonitor = nil
    }
}
