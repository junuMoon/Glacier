import AppKit

// MARK: - NSEvent monitor handle

/// AppKit returns an untyped object from `addLocalMonitorForEvents` / `addGlobalMonitorForEvents`;
/// we keep it in one place so call sites stay strongly typed.
private struct NSEventMonitorHandle {
    fileprivate let untypedToken: Any

    @MainActor
    static func installLocal(
        matching mask: NSEvent.EventTypeMask,
        handler: @escaping (NSEvent) -> NSEvent?
    ) -> NSEventMonitorHandle? {
        guard let token = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler) else {
            return nil
        }
        return NSEventMonitorHandle(untypedToken: token)
    }

    @MainActor
    static func installGlobal(
        matching mask: NSEvent.EventTypeMask,
        handler: @escaping (NSEvent) -> Void
    ) -> NSEventMonitorHandle? {
        guard let token = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) else {
            return nil
        }
        return NSEventMonitorHandle(untypedToken: token)
    }

    @MainActor
    func remove() {
        NSEvent.removeMonitor(untypedToken)
    }
}

// MARK: - Controller

@MainActor
final class EventMonitorController {
    /// Local only: `LSUIElement` apps rarely become key; Esc works when a Glacier window/menu has keyboard focus.
    private var escapeKeyLocalMonitor: NSEventMonitorHandle?
    private var commandLayoutSyncMonitor: NSEventMonitorHandle?
    private var layoutSyncDebounce: DispatchWorkItem?

    private var onInput: ((GlacierInput) -> Void)?
    private var onLayoutSyncAfterCmdDrag: (() -> Void)?

    func update(
        for state: GlacierState,
        onInput: @escaping (GlacierInput) -> Void,
        onLayoutSyncAfterCmdDrag: (() -> Void)? = nil
    ) {
        self.onInput = onInput
        self.onLayoutSyncAfterCmdDrag = onLayoutSyncAfterCmdDrag
        stopEventMonitors()
        layoutSyncDebounce?.cancel()
        layoutSyncDebounce = nil

        if state != .closed {
            escapeKeyLocalMonitor = NSEventMonitorHandle.installLocal(matching: [.keyDown]) { [weak self] event in
                guard let self else { return event }
                guard event.keyCode == 53 else { return event } // Escape
                guard !event.modifierFlags.contains(.command) else { return event }
                self.onInput?(.escape)
                return nil
            }
        }

        if onLayoutSyncAfterCmdDrag != nil {
            commandLayoutSyncMonitor = NSEventMonitorHandle.installGlobal(matching: [.leftMouseUp]) { [weak self] event in
                guard event.modifierFlags.contains(.command) else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    guard self.isPointInMenuBar(NSEvent.mouseLocation) else { return }
                    self.scheduleDebouncedLayoutSync()
                }
            }
        }
    }

    func invalidate() {
        onInput = nil
        onLayoutSyncAfterCmdDrag = nil
        layoutSyncDebounce?.cancel()
        layoutSyncDebounce = nil
        stopEventMonitors()
    }

    private func stopEventMonitors() {
        escapeKeyLocalMonitor?.remove()
        commandLayoutSyncMonitor?.remove()
        escapeKeyLocalMonitor = nil
        commandLayoutSyncMonitor = nil
    }

    private func scheduleDebouncedLayoutSync() {
        layoutSyncDebounce?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.layoutSyncDebounce = nil
            self.onLayoutSyncAfterCmdDrag?()
        }
        layoutSyncDebounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: work)
    }

    private func isPointInMenuBar(_ point: NSPoint) -> Bool {
        for screen in NSScreen.screens where screen.frame.contains(point) {
            let menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
            guard menuBarHeight > 0 else { continue }

            let menuBarRect = NSRect(
                x: screen.frame.minX,
                y: screen.frame.maxY - menuBarHeight,
                width: screen.frame.width,
                height: menuBarHeight
            )
            if menuBarRect.contains(point) { return true }
        }
        return false
    }
}
