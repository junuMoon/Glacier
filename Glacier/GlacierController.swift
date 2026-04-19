import AppKit
import ServiceManagement

@MainActor
final class GlacierController {

    private static let sectionAutoHideDelay: TimeInterval = 60

    // MARK: - State

    private var stateMachine = GlacierStateMachine()
    private var sectionAutoHideWorkItem: DispatchWorkItem?

    // MARK: - NSStatusItems

    private let glacierIcon: NSStatusItem  // ● user-facing icon
    private let sep1: NSStatusItem         // separator just left of ●
    private let diamond: NSStatusItem      // ◆ always-hidden boundary marker
    private let sep2: NSStatusItem         // separator just left of ◆

    // MARK: - Collaborators

    private let layoutController: MenuBarLayoutController
    private let eventMonitorController = EventMonitorController()

    // MARK: - Init

    init() {
        MenuBarLayoutController.seedDefaultPositionsIfNeeded()

        glacierIcon = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        glacierIcon.autosaveName = "GlacierIcon"

        sep1 = NSStatusBar.system.statusItem(withLength: 0)
        sep1.autosaveName = "GlacierSep"

        diamond = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        diamond.autosaveName = "GlacierDiamond"

        sep2 = NSStatusBar.system.statusItem(withLength: 0)
        sep2.autosaveName = "GlacierSep2"

        layoutController = MenuBarLayoutController(
            glacierIcon: glacierIcon,
            sep1: sep1,
            diamond: diamond,
            sep2: sep2
        )

        // ● icon button
        if let button = glacierIcon.button {
            button.target = self
            button.action = #selector(primaryControlClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseDown])
        }

        if let button = diamond.button {
            button.target = self
            button.action = #selector(boundaryControlClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseDown])
        }

        sep1.button?.cell?.isEnabled = false
        sep2.button?.cell?.isEnabled = false

        applyCurrentState()
    }

    // MARK: - State Transitions

    private func applyCurrentState() {
        layoutController.apply(state: stateMachine.state)
        eventMonitorController.update(
            for: stateMachine.state,
            onInput: { [weak self] input in
                self?.handle(input)
            },
            onLayoutSyncAfterCmdDrag: { [weak self] in
                self?.resyncLayoutAfterPossibleCmdDrag()
            }
        )
        rescheduleSectionAutoHideIfNeeded()
    }

    /// After one minute in an expanded (non-editing) layout, collapse back to `.closed` like Esc.
    private func rescheduleSectionAutoHideIfNeeded() {
        sectionAutoHideWorkItem?.cancel()
        sectionAutoHideWorkItem = nil

        switch stateMachine.state {
        case .hiddenOpen, .allOpen:
            let work = DispatchWorkItem { [weak self] in
                guard let self else { return }
                self.sectionAutoHideWorkItem = nil
                let s = self.stateMachine.state
                guard s == .hiddenOpen || s == .allOpen else { return }
                self.handle(.escape)
            }
            sectionAutoHideWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + Self.sectionAutoHideDelay, execute: work)
        case .closed, .editing:
            break
        }
    }

    /// After Cmd+Drag in the menu bar, macOS updates `NSStatusItem` autosave slots in UserDefaults; re-apply layout.
    private func resyncLayoutAfterPossibleCmdDrag() {
        layoutController.apply(state: stateMachine.state)
    }

    private func handle(_ input: GlacierInput) {
        stateMachine.handle(input)
        applyCurrentState()
    }

    func prepareForTermination() {
        sectionAutoHideWorkItem?.cancel()
        sectionAutoHideWorkItem = nil
        eventMonitorController.invalidate()
    }

    // MARK: - Click Handling

    @objc private func primaryControlClicked(_ sender: NSStatusBarButton) {
        handleControlClick(sender: sender, isBoundary: false)
    }

    @objc private func boundaryControlClicked(_ sender: NSStatusBarButton) {
        handleControlClick(sender: sender, isBoundary: true)
    }

    private func handleControlClick(sender: NSStatusBarButton, isBoundary: Bool) {
        guard let event = NSApp.currentEvent else { return }

        if event.modifierFlags.contains(.command) { return }
        if event.type == .rightMouseDown {
            showContextMenu(anchoredTo: sender)
        } else if event.modifierFlags.contains(.option) {
            handle(.alternateClick)
        } else if isBoundary {
            handle(.boundaryClick)
        } else {
            handle(.primaryClick)
        }
    }

    // MARK: - Context Menu

    private func showContextMenu(anchoredTo anchorButton: NSStatusBarButton) {
        let menu = NSMenu()

        let usageItem = NSMenuItem(title: "Usage", action: #selector(showUsage), keyEquivalent: "")
        usageItem.target = self
        menu.addItem(usageItem)

        let editTitle = stateMachine.state == .editing ? "Done Editing" : "Edit Layout"
        let editItem = NSMenuItem(title: editTitle, action: #selector(toggleEditingMode), keyEquivalent: "")
        editItem.target = self
        menu.addItem(editItem)

        let resetItem = NSMenuItem(title: "Reset Layout", action: #selector(resetLayout), keyEquivalent: "")
        resetItem.target = self
        menu.addItem(resetItem)

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = isLaunchAtLoginEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        menu.addItem(NSMenuItem(
            title: "Quit Glacier",
            action: #selector(NSApp.terminate(_:)),
            keyEquivalent: "q"
        ))
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: anchorButton.bounds.maxY + 5), in: anchorButton)
    }

    @objc private func showUsage() {
        struct UsageSection {
            let title: String
            let body: String
        }

        let diagramLine = "[Always Hidden] ◆ [Hidden] ● [Visible]"
        let sections: [UsageSection] = [
            UsageSection(title: "Click ●", body: "Show / hide hidden section"),
            UsageSection(title: "Click ◆ after opening hidden", body: "Show / hide items left of ◆"),
            UsageSection(title: "Option + Click ● or ◆", body: "Show / hide always-hidden section"),
            UsageSection(
                title: "Press Esc",
                body: "Hide open sections when Glacier (or its open menu) has keyboard focus; otherwise use ● or wait for the one-minute timeout"
            ),
            UsageSection(
                title: "One-minute timeout",
                body: "Hidden or fully open layout collapses automatically after 60 seconds (timer resets when you switch between those two)"
            ),
            UsageSection(title: "Right-click ● or ◆", body: "Usage, Edit Layout, Reset Layout, Launch at Login, Quit"),
            UsageSection(title: "Edit Layout + Cmd + Drag ● ◆", body: "Rearrange sections"),
        ]

        let font = NSFont.systemFont(ofSize: 12)
        let boldFont = NSFont.boldSystemFont(ofSize: 12)
        let monoFont = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let result = NSMutableAttributedString()

        // Layout diagram
        let diagram = NSAttributedString(
            string: diagramLine + "\n\n",
            attributes: [.font: monoFont, .foregroundColor: NSColor.secondaryLabelColor]
        )
        result.append(diagram)

        // Action items
        for (index, section) in sections.enumerated() {
            let action = NSAttributedString(string: section.title + "\n", attributes: [.font: boldFont])
            let desc = NSAttributedString(string: section.body, attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor])
            result.append(action)
            result.append(desc)
            if index < sections.count - 1 {
                result.append(NSAttributedString(string: "\n\n"))
            }
        }

        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 260, height: 0))
        textView.isEditable = false
        textView.isSelectable = false
        textView.drawsBackground = false
        textView.textStorage?.setAttributedString(result)
        textView.sizeToFit()

        let alert = NSAlert()
        alert.messageText = "Glacier Usage"
        alert.informativeText = ""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.accessoryView = textView
        alert.runModal()
    }

    @objc private func toggleEditingMode() {
        if stateMachine.state == .editing {
            handle(.finishEditing)
        } else {
            handle(.enterEditing)
        }
    }

    @objc private func resetLayout() {
        layoutController.resetToDefaultPositions()
        handle(.finishEditing)
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if isLaunchAtLoginEnabled() {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to Update Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func isLaunchAtLoginEnabled() -> Bool {
        switch SMAppService.mainApp.status {
        case .enabled:
            true
        case .requiresApproval, .notFound, .notRegistered:
            false
        @unknown default:
            false
        }
    }
}
