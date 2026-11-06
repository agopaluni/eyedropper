import AppKit
import Carbon.HIToolbox
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    let state = AppState()
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var hotKey: HotKey?
    private var sampler: NSColorSampler?
    private var flashWork: DispatchWorkItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = Self.eyedropperImage
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Eyedropper: click for details, right-click to pick (⌃⌥⌘C)"
        }

        state.requestPick = { [weak self] in self?.startPicking(reopenPopover: true) }

        let host = NSHostingController(rootView: PopoverView().environmentObject(state))
        host.sizingOptions = .preferredContentSize
        popover.contentViewController = host
        popover.behavior = .transient
        popover.animates = true

        // ⌃⌥⌘C from anywhere: pick and copy, without opening the popover.
        let hk = HotKey(keyCode: kVK_ANSI_C, modifiers: cmdKey | optionKey | controlKey) { [weak self] in
            self?.startPicking(reopenPopover: false)
        }
        hotKey = hk
        state.hotKeyRegistered = hk.isRegistered
    }

    // MARK: Status item

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let wantsQuickPick = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        if wantsQuickPick {
            startPicking(reopenPopover: false)
        } else if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    // MARK: Picking

    private func startPicking(reopenPopover: Bool) {
        guard sampler == nil else { return }
        let wasShown = popover.isShown
        popover.performClose(nil)
        // Let the popover finish closing so it isn't in the way of the loupe.
        DispatchQueue.main.asyncAfter(deadline: .now() + (wasShown ? 0.2 : 0.0)) { [weak self] in
            guard let self else { return }
            let sampler = NSColorSampler()
            self.sampler = sampler
            sampler.show { picked in
                DispatchQueue.main.async { self.finishPicking(picked, reopenPopover: reopenPopover) }
            }
        }
    }

    private func finishPicking(_ picked: NSColor?, reopenPopover: Bool) {
        sampler = nil
        if let picked, let rgb = RGB(nsColor: picked) {
            state.remember(rgb)
            if state.autoCopy, let hex = state.hexString { state.copy(hex) }
            flash(rgb)
        }
        if reopenPopover { showPopover() }
    }

    /// Briefly shows the picked color and its hex in the menu bar.
    private func flash(_ c: RGB) {
        guard let button = statusItem.button else { return }
        flashWork?.cancel()
        let text = " " + c.hex(uppercase: state.uppercase, hash: state.includeHash) + (state.autoCopy ? "  copied" : "")
        button.image = Self.swatchImage(c)
        button.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
        ])
        let work = DispatchWorkItem {
            button.image = Self.eyedropperImage
            button.title = ""
        }
        flashWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }

    // MARK: Images

    private static let eyedropperImage: NSImage = {
        let image = NSImage(systemSymbolName: "eyedropper.halffull", accessibilityDescription: "Eyedropper")
            ?? NSImage(systemSymbolName: "eyedropper", accessibilityDescription: "Eyedropper")!
        image.isTemplate = true
        return image
    }()

    private static func swatchImage(_ c: RGB) -> NSImage {
        let size = NSSize(width: 14, height: 14)
        let image = NSImage(size: size, flipped: false) { rect in
            let path = NSBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            c.nsColor.setFill()
            path.fill()
            NSColor.labelColor.withAlphaComponent(0.35).setStroke()
            path.lineWidth = 1
            path.stroke()
            return true
        }
        image.isTemplate = false
        return image
    }
}
