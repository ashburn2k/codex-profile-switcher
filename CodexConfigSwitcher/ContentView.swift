import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ProfileStore
    @State private var selectedProfile: CodexProfile?

    private let sidebarWidth: CGFloat = 206
    private let detailWidth: CGFloat = 558
    private let panelHeight: CGFloat = 344

    private var profileCountText: String {
        "\(store.profiles.count) profile\(store.profiles.count == 1 ? "" : "s")"
    }

    private var profileListHeight: CGFloat {
        let headerAndPadding: CGFloat = 6
        let rowHeight: CGFloat = 42
        let count = CGFloat(min(max(store.profiles.count, 1), 6))
        return headerAndPadding + rowHeight * count
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            sidebar
                .frame(width: sidebarWidth)

            detail
                .frame(width: detailWidth)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(AppBackdrop())
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.refresh()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }

                Button {
                    store.revealCodexFolder()
                } label: {
                    Label("Open .codex", systemImage: "folder")
                }
            }
        }
        .onAppear {
            selectedProfile = store.profiles.first
        }
        .onChange(of: store.profiles) { _, profiles in
            if selectedProfile == nil || !profiles.contains(where: { $0.id == selectedProfile?.id }) {
                selectedProfile = profiles.first
            }
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            SidebarHeader(profileCountText: profileCountText)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 6)

            profileList
                .frame(height: profileListHeight)

            Divider()

            sidebarFooter
                .padding(10)
        }
        .frame(height: panelHeight, alignment: .top)
        .switcherGlassPanel(material: .thinMaterial, isInteractive: false)
    }

    private var profileList: some View {
        List(store.profiles, selection: $selectedProfile) { profile in
            ProfileRow(profile: profile)
                .tag(profile)
                .padding(.vertical, 2)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(.clear)
        .scrollDisabled(store.profiles.count <= 6)
    }

    private var sidebarFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            savePanel

            if !store.statusMessage.isEmpty {
                Divider()
                SidebarStatus(message: store.statusMessage)
            }
        }
    }

    private var savePanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Save Current Setup", systemImage: "plus.circle.fill")
                .font(.body.weight(.semibold))

            TextField("New profile name", text: $store.newProfileName)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 3) {
                Toggle("config.toml", isOn: $store.includeConfig)
                Toggle("auth.json", isOn: $store.includeAuth)
            }
            .toggleStyle(.checkbox)
            .font(.body)

            Button {
                store.saveCurrentAsProfile()
            } label: {
                Label("Save Profile", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .disabled(store.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedProfile {
            detailPanel(for: selectedProfile)
        } else {
            emptyState
        }
    }

    private func detailPanel(for profile: CodexProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            profileSummary(for: profile)

            PanelDivider()

            HStack(alignment: .top, spacing: 16) {
                InlineMetric(
                    title: "Active Files",
                    value: store.activeSummary,
                    systemImage: "checkmark.shield",
                    tint: .green
                )

                InlineMetric(
                    title: "Profile Source",
                    value: profile.source == .folder ? "Folder profile" : "Loose ~/.codex files",
                    systemImage: profile.source == .folder ? "folder" : "doc.on.doc",
                    tint: .blue
                )
            }

            PanelDivider()

            fileSection(for: profile)

            PanelDivider()

            switchSection(for: profile)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: panelHeight, alignment: .topLeading)
        .switcherGlassPanel(material: .regularMaterial, isInteractive: true)
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 5)
    }

    private func profileSummary(for profile: CodexProfile) -> some View {
        HStack(alignment: .center, spacing: 10) {
            ProfileIcon(profile: profile, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.title.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(profile.detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                HStack(spacing: 6) {
                    ProfileBadge(text: "config", systemImage: "doc.text", isActive: profile.hasConfig)
                    ProfileBadge(text: "auth", systemImage: "key", isActive: profile.hasAuth)
                }
            }

            Spacer(minLength: 10)

            Button {
                store.revealProfile(profile)
            } label: {
                Label("Reveal", systemImage: "magnifyingglass")
            }
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
        }
    }

    private func fileSection(for profile: CodexProfile) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionTitle("Profile Files", systemImage: "tray.full")

            VStack(spacing: 4) {
                FileRow(title: "config.toml", systemImage: "doc.text", url: profile.configURL)
                Divider()
                FileRow(title: "auth.json", systemImage: "key", url: profile.authURL)
            }
        }
    }

    private func switchSection(for profile: CodexProfile) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("Switch Profile", systemImage: "arrow.triangle.2.circlepath")

            Toggle("Relaunch Codex after switch", isOn: $store.relaunchCodexAfterSwitch)
                .toggleStyle(.switch)
                .font(.body)

            HStack(spacing: 10) {
                Button {
                    store.switchToProfile(profile)
                } label: {
                    Label(
                        store.relaunchCodexAfterSwitch ? "Switch and Relaunch Codex" : "Switch to This Profile",
                        systemImage: store.relaunchCodexAfterSwitch ? "arrow.clockwise.circle" : "arrow.triangle.2.circlepath"
                    )
                    .frame(minWidth: 210)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)

                Button {
                    store.revealProfile(profile)
                } label: {
                    Label("Reveal Profile", systemImage: "folder")
                }
                .buttonBorderShape(.capsule)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Profiles Found",
            systemImage: "switch.2",
            description: Text("Create a profile from your current Codex files or add folders under ~/.codex/profiles.")
        )
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .switcherGlassPanel(material: .regularMaterial, isInteractive: false)
    }
}

private struct AppBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color.accentColor.opacity(0.10),
                    Color.white.opacity(0.42)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GlassSheen()
        }
        .ignoresSafeArea()
    }
}

private struct GlassSheen: View {
    var body: some View {
        Canvas { context, size in
            let leftRect = CGRect(x: -size.width * 0.06, y: size.height * 0.18, width: size.width * 0.42, height: size.height * 0.78)
            let rightRect = CGRect(x: size.width * 0.54, y: -size.height * 0.18, width: size.width * 0.56, height: size.height * 0.72)

            context.fill(Path(ellipseIn: leftRect), with: .color(Color.blue.opacity(0.10)))
            context.fill(Path(ellipseIn: rightRect), with: .color(Color.cyan.opacity(0.10)))
        }
        .blur(radius: 32)
        .allowsHitTesting(false)
    }
}

private struct SidebarHeader: View {
    let profileCountText: String

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.14))

                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Codex Switcher")
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(profileCountText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

private struct ProfileRow: View {
    let profile: CodexProfile

    var body: some View {
        HStack(spacing: 9) {
            ProfileIcon(profile: profile, size: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)

                HStack(spacing: 7) {
                    AvailabilityDot(isActive: profile.hasConfig, label: "config")
                    AvailabilityDot(isActive: profile.hasAuth, label: "auth")
                }
            }

            Spacer(minLength: 0)
        }
        .contentShape(Rectangle())
    }
}

private struct ProfileIcon: View {
    let profile: CodexProfile
    let size: CGFloat

    private var tint: Color {
        profile.source == .folder ? .blue : .orange
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(tint.opacity(0.16))

            Image(systemName: profile.source == .folder ? "folder.fill" : "doc.on.doc.fill")
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
    }
}

private struct InlineMetric: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionTitle(title, systemImage: systemImage, tint: tint)

            Text(value)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }
}

private struct SectionTitle: View {
    let title: String
    let systemImage: String
    let tint: Color

    init(_ title: String, systemImage: String, tint: Color = .accentColor) {
        self.title = title
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        Label {
            Text(title)
                .font(.headline.weight(.semibold))
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }
}

private struct FileRow: View {
    let title: String
    let systemImage: String
    let url: URL?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(url == nil ? Color.secondary : Color.accentColor)
                .frame(width: 18)

            Text(title)
                .font(.body.weight(.semibold))
                .frame(width: 104, alignment: .leading)

            PathText(url: url)

            Spacer(minLength: 0)
        }
    }
}

private struct ProfileBadge: View {
    let text: String
    let systemImage: String
    let isActive: Bool

    var body: some View {
        Label(text, systemImage: isActive ? systemImage : "minus.circle")
            .font(.callout.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isActive ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.12))
            .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct AvailabilityDot: View {
    let isActive: Bool
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isActive ? "checkmark.circle.fill" : "minus.circle")
                .font(.caption2.weight(.bold))
                .foregroundStyle(isActive ? Color.green : Color.secondary)

            Text(label)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}

private struct PathText: View {
    let url: URL?

    var body: some View {
        if let url {
            Text(url.path)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        } else {
            Text("Not included")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PanelDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, 6)
    }
}

private struct SidebarStatus: View {
    let message: String

    private var tone: StatusTone {
        StatusTone(message: message)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 7) {
            Image(systemName: tone.systemImage)
                .font(.callout.weight(.semibold))
                .foregroundStyle(tone.tint)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .textSelection(.enabled)
        }
    }
}

private enum StatusTone {
    case success
    case warning
    case neutral

    init(message: String) {
        if message.localizedCaseInsensitiveContains("failed")
            || message.localizedCaseInsensitiveContains("fail")
            || message.localizedCaseInsensitiveContains("error") {
            self = .warning
        } else if message.localizedCaseInsensitiveContains("saved")
            || message.localizedCaseInsensitiveContains("switched")
            || message.localizedCaseInsensitiveContains("loaded") {
            self = .success
        } else {
            self = .neutral
        }
    }

    var tint: Color {
        switch self {
        case .success:
            return .green
        case .warning:
            return .orange
        case .neutral:
            return .accentColor
        }
    }

    var systemImage: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .neutral:
            return "info.circle.fill"
        }
    }
}

private struct SwitcherGlassPanel: ViewModifier {
    let material: Material
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            if isInteractive {
                content
                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.28))
                    }
            } else {
                content
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.24))
                    }
            }
        } else {
            content
                .background(material, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.primary.opacity(0.08))
                }
        }
    }
}

private extension View {
    func switcherGlassPanel(material: Material, isInteractive: Bool) -> some View {
        modifier(SwitcherGlassPanel(material: material, isInteractive: isInteractive))
    }
}
