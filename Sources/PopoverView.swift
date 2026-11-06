import SwiftUI

struct PopoverView: View {
    @EnvironmentObject private var state: AppState
    @State private var copiedKey: String?
    @State private var hovered: ColorFormat?
    @State private var input = ""
    @State private var inputInvalid = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            pickButton
            if let c = state.current { formats(c) }
            inputField
            if !state.history.isEmpty { recent }
            Divider()
            settings
            footer
        }
        .padding(14)
        .frame(width: 320)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(state.current?.color ?? .clear)
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.18),
                                  style: StrokeStyle(lineWidth: 1, dash: state.current == nil ? [4, 3] : []))
            }
            .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                if let c = state.current, let hex = state.hexString {
                    Button { copy(hex, key: "hero") } label: {
                        HStack(spacing: 6) {
                            Text(hex)
                                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                            copyIcon(for: "hero")
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Copy HEX")
                    HStack(spacing: 6) {
                        contrastChip(c, on: .white)
                        contrastChip(c, on: .black)
                    }
                } else {
                    Text("No color yet").font(.headline)
                    Text("Pick anything on your screen.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
    }

    /// "Aa" in the picked color on white / black, with its WCAG contrast ratio.
    private func contrastChip(_ c: RGB, on bg: RGB) -> some View {
        let ratio = c.contrast(with: bg)
        let grade = ratio >= 7 ? "AAA" : ratio >= 4.5 ? "AA" : ratio >= 3 ? "AA18" : "Fail"
        let ink: Color = bg == .white ? .black : .white
        return HStack(spacing: 4) {
            Text("Aa").font(.system(size: 11, weight: .bold)).foregroundStyle(c.color)
            Text(String(format: "%.1f", ratio)).font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(ink.opacity(0.75))
            Text(grade).font(.system(size: 9, weight: .semibold))
                .foregroundStyle(ink.opacity(0.55))
        }
        .padding(.horizontal, 6).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 5).fill(bg.color))
        .overlay(RoundedRectangle(cornerRadius: 5).strokeBorder(Color.primary.opacity(0.15)))
        .help(String(format: "Contrast ratio %.2f:1 on %@ (WCAG %@)", ratio, bg == .white ? "white" : "black", grade))
    }

    // MARK: Pick

    private var pickButton: some View {
        Button { state.requestPick?() } label: {
            HStack {
                Image(systemName: "eyedropper")
                Text("Pick Color").fontWeight(.medium)
                Spacer()
                if state.hotKeyRegistered {
                    Text("⌃⌥⌘C").font(.system(size: 11, design: .monospaced)).opacity(0.75)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .keyboardShortcut("p")
    }

    // MARK: Formats

    private func formats(_ c: RGB) -> some View {
        VStack(spacing: 1) {
            ForEach(ColorFormat.allCases) { f in
                let value = state.string(f, for: c)
                Button { copy(value, key: f.rawValue) } label: {
                    HStack(spacing: 8) {
                        Text(f.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 48, alignment: .leading)
                        Text(value)
                            .font(.system(size: 12, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer(minLength: 4)
                        copyIcon(for: f.rawValue)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 5)
                    .contentShape(Rectangle())
                    .background(RoundedRectangle(cornerRadius: 6)
                        .fill(hovered == f ? Color.primary.opacity(0.07) : .clear))
                }
                .buttonStyle(.plain)
                .help("Copy \(value)")
                .onHover { hovered = $0 ? f : (hovered == f ? nil : hovered) }
            }
        }
        .padding(.horizontal, -8)
    }

    private func copyIcon(for key: String) -> some View {
        let done = copiedKey == key
        return Image(systemName: done ? "checkmark" : "doc.on.doc")
            .font(.system(size: 11, weight: done ? .bold : .regular))
            .foregroundStyle(done ? Color.green : Color.secondary)
            .frame(width: 14)
    }

    // MARK: Input

    private var inputField: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField("Paste a hex or rgb to convert", text: $input)
                .textFieldStyle(.roundedBorder)
                .font(.system(size: 12, design: .monospaced))
                .onSubmit {
                    if let c = RGB.parse(input) {
                        state.remember(c)
                        input = ""
                    } else {
                        inputInvalid = !input.isEmpty
                    }
                }
                .onChange(of: input) { inputInvalid = false }
            if inputInvalid {
                Text("Couldn't read that. Try #1A2B3C, 1a2b3c, #abc or rgb(26, 43, 60).")
                    .font(.caption).foregroundStyle(.red)
            }
        }
    }

    // MARK: Recent

    private var recent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Recent").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                Spacer()
                Button("Clear") { state.clearHistory() }
                    .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 9), count: 8),
                      alignment: .leading, spacing: 9) {
                ForEach(state.history, id: \.self) { c in
                    let selected = c == state.current
                    Circle()
                        .fill(c.color)
                        .overlay(Circle().strokeBorder(Color.primary.opacity(selected ? 0.85 : 0.18),
                                                       lineWidth: selected ? 2 : 1))
                        .frame(width: 26, height: 26)
                        .contentShape(Circle())
                        .onTapGesture { state.current = c }
                        .help(c.hex(uppercase: state.uppercase, hash: state.includeHash))
                        .contextMenu {
                            Button("Copy HEX") { state.copy(state.string(.hex, for: c)) }
                            Button("Copy RGB") { state.copy(state.string(.rgb, for: c)) }
                            Divider()
                            Button("Remove") { state.remove(c) }
                        }
                }
            }
        }
    }

    // MARK: Settings

    private var settings: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Copy HEX to clipboard after picking", isOn: $state.autoCopy)
            HStack(spacing: 16) {
                Toggle("Uppercase", isOn: $state.uppercase)
                Toggle("Include #", isOn: $state.includeHash)
            }
            Toggle("Launch at login", isOn: Binding(
                get: { state.launchAtLogin },
                set: { state.setLaunchAtLogin($0) }
            ))
            if let err = state.loginError {
                Text(err).font(.caption).foregroundStyle(.red)
            }
        }
        .toggleStyle(.checkbox)
        .font(.callout)
    }

    private var footer: some View {
        HStack {
            Text("Right-click the menu bar icon to pick instantly.")
                .font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q")
                .controlSize(.small)
        }
    }

    private func copy(_ s: String, key: String) {
        state.copy(s)
        withAnimation(.easeOut(duration: 0.15)) { copiedKey = key }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            if copiedKey == key { withAnimation { copiedKey = nil } }
        }
    }
}
