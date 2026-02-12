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

    private enum State { case allHidden, partialShow, showAll }
    private var state: State = .allHidden

    // MARK: - NSStatusItems

    private let glacierIcon: NSStatusItem  // ● user-facing icon
    private let sep1: NSStatusItem         // separator just left of ●
    private let diamond: NSStatusItem      // ◆ always-hidden boundary marker
    private let sep2: NSStatusItem         // separator just left of ◆

    // MARK: - Event Monitors

    private var globalMonitor: Any?
    private var localMonitor: Any?

    // MARK: - Init

    init() {
        // Set preferred positions BEFORE creating status items
        // so macOS places them in the correct order.
        // Position 0 = rightmost; higher numbers = further left.
        let ud = UserDefaults.standard
        if ud.object(forKey: "NSStatusItem Preferred Position GlacierIcon") == nil {
            ud.set(0, forKey: "NSStatusItem Preferred Position GlacierIcon")
        }
        if ud.object(forKey: "NSStatusItem Preferred Position GlacierSep") == nil {
            ud.set(1, forKey: "NSStatusItem Preferred Position GlacierSep")
        }
        if ud.object(forKey: "NSStatusItem Preferred Position GlacierDiamond") == nil {
            ud.set(2, forKey: "NSStatusItem Preferred Position GlacierDiamond")
        }
        if ud.object(forKey: "NSStatusItem Preferred Position GlacierSep2") == nil {
            ud.set(3, forKey: "NSStatusItem Preferred Position GlacierSep2")
        }

        glacierIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        glacierIcon.autosaveName = "GlacierIcon"

        sep1 = NSStatusBar.system.statusItem(withLength: 0)
        sep1.autosaveName = "GlacierSep"

        diamond = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        diamond.autosaveName = "GlacierDiamond"

        sep2 = NSStatusBar.system.statusItem(withLength: 0)
        sep2.autosaveName = "GlacierSep2"

        // ● icon button
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

        // ◆ diamond marker (non-clickable)
        if let button = diamond.button {
            let config = NSImage.SymbolConfiguration(pointSize: 6, weight: .regular)
            button.image = NSImage(
                systemSymbolName: "diamond.fill",
                accessibilityDescription: "Glacier Always Hidden"
            )?.withSymbolConfiguration(config)
            button.cell?.isEnabled = false
        }

        sep1.button?.cell?.isEnabled = false
        sep2.button?.cell?.isEnabled = false

        if !AXIsProcessTrusted() && !UserDefaults.standard.bool(forKey: "AccessibilityPrompted") {
            UserDefaults.standard.set(true, forKey: "AccessibilityPrompted")
            requestAccessibilityIfNeeded()
        }

        hideAll()
    }

    // MARK: - State Transitions

    private func hideAll() {
        state = .allHidden

        let ud = UserDefaults.standard
        let iconPos = ud.double(forKey: "NSStatusItem Preferred Position GlacierIcon")
        let newSep1Pos = iconPos + 1
        ud.set(newSep1Pos, forKey: "NSStatusItem Preferred Position GlacierSep")

        // isVisible toggle forces macOS to recalculate position
        sep1.isVisible = false
        ud.set(newSep1Pos, forKey: "NSStatusItem Preferred Position GlacierSep")
        sep1.isVisible = true

        sep1.length = 10_000
        // sep2 doesn't matter — sep1 already pushes everything off-screen
        stopEventMonitors()
    }

    private func showPartial() {
        state = .partialShow

        sep1.length = NSStatusItem.variableLength

        let ud = UserDefaults.standard
        let diamondPos = ud.double(forKey: "NSStatusItem Preferred Position GlacierDiamond")
        let newSep2Pos = diamondPos + 1
        ud.set(newSep2Pos, forKey: "NSStatusItem Preferred Position GlacierSep2")

        sep2.isVisible = false
        ud.set(newSep2Pos, forKey: "NSStatusItem Preferred Position GlacierSep2")
        sep2.isVisible = true

        sep2.length = 10_000
        startEventMonitors()
    }

    private func showAll() {
        state = .showAll
        sep1.length = NSStatusItem.variableLength
        sep2.length = NSStatusItem.variableLength
        startEventMonitors()
    }

    // MARK: - Click Handling

    @objc private func iconClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else if event.modifierFlags.contains(.option) {
            // Option+click: showAll ↔ allHidden toggle
            if state == .showAll { hideAll() } else { showAll() }
        } else {
            // Normal click: allHidden ↔ partialShow toggle
            switch state {
            case .allHidden: showPartial()
            case .partialShow, .showAll: hideAll()
            }
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
                self?.hideAll()
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] event in
            if event.window?.className.contains("NSStatusBarWindow") == false {
                MainActor.assumeIsolated {
                    self?.hideAll()
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
