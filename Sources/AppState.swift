import AppKit
import ServiceManagement
import SwiftUI

final class AppState: ObservableObject {
    private let defaults = UserDefaults.standard
    private let historyLimit = 16

    @Published var current: RGB? {
        didSet { defaults.set(current?.hex(), forKey: "current") }
    }
    @Published private(set) var history: [RGB] = []

    @Published var autoCopy: Bool { didSet { defaults.set(autoCopy, forKey: "autoCopy") } }
    @Published var uppercase: Bool { didSet { defaults.set(uppercase, forKey: "uppercase") } }
    @Published var includeHash: Bool { didSet { defaults.set(includeHash, forKey: "includeHash") } }
    @Published var loginError: String?
    @Published var hotKeyRegistered = false

    /// Set by the app delegate; the popover's Pick button calls it.
    var requestPick: (() -> Void)?

    init() {
        defaults.register(defaults: ["autoCopy": true, "uppercase": true, "includeHash": true])
        autoCopy = defaults.bool(forKey: "autoCopy")
        uppercase = defaults.bool(forKey: "uppercase")
        includeHash = defaults.bool(forKey: "includeHash")
        history = (defaults.stringArray(forKey: "history") ?? []).compactMap { RGB(hex: $0) }
        current = defaults.string(forKey: "current").flatMap { RGB(hex: $0) } ?? history.first
    }

    var hexString: String? { current.map { $0.hex(uppercase: uppercase, hash: includeHash) } }

    func string(_ format: ColorFormat, for c: RGB) -> String {
        format.string(c, uppercase: uppercase, hash: includeHash)
    }

    /// Makes `c` the current color and moves it to the front of Recent.
    func remember(_ c: RGB) {
        current = c
        history.removeAll { $0 == c }
        history.insert(c, at: 0)
        if history.count > historyLimit { history.removeLast(history.count - historyLimit) }
        saveHistory()
    }

    func remove(_ c: RGB) {
        history.removeAll { $0 == c }
        saveHistory()
    }

    func clearHistory() {
        history.removeAll()
        saveHistory()
    }

    private func saveHistory() {
        defaults.set(history.map { $0.hex() }, forKey: "history")
    }

    func copy(_ s: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s, forType: .string)
    }

    var launchAtLogin: Bool { SMAppService.mainApp.status == .enabled }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
            loginError = nil
        } catch {
            loginError = "Couldn't change login item: \(error.localizedDescription)"
        }
        objectWillChange.send()
    }
}
