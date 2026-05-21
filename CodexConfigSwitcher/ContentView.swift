import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ProfileStore
    @State private var selectedProfile: CodexProfile?

    private var profileCountText: String {
        "\(store.profiles.count) profile\(store.profiles.count == 1 ? "" : "s")"
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
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
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 10)

            List(store.profiles, selection: $selectedProfile) { profile in
                ProfileRow(profile: profile)
                    .tag(profile)
                    .padding(.vertical, 4)
            }
            .listStyle(.sidebar)
            .navigationTitle("Profiles")

            Divider()

            savePanel
                .padding(14)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
    }

    private var savePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Save Current Setup", systemImage: "plus.circle.fill")
                .font(.headline)

            TextField("New profile name", text: $store.newProfileName)
                .textFieldStyle(.roundedBorder)

            HStack(spacing: 14) {
                Toggle("config.toml", isOn: $store.includeConfig)
                Toggle("auth.json", isOn: $store.includeAuth)
            }
            .toggleStyle(.checkbox)
            .font(.callout)

            Button {
                store.saveCurrentAsProfile()
            } label: {
                Label("Save Profile", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.newProfileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedProfile {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    profileHeader(for: selectedProfile)

                    HStack(alignment: .top, spacing: 18) {
                        activeFilesCard
                        sourceCard(for: selectedProfile)
                    }

                    fileCard(for: selectedProfile)
                    switchCard(for: selectedProfile)

                    if !store.statusMessage.isEmpty {
                        StatusBanner(message: store.statusMessage)
                    }
                }
                .padding(28)
                .frame(maxWidth: 860, alignment: .leading)
            }
            .background(Color(nsColor: .textBackgroundColor))
        } else {
            emptyState
        }
    }

    private func profileHeader(for profile: CodexProfile) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ProfileIcon(profile: profile, size: 58)

            VStack(alignment: .leading, spacing: 8) {
                Text(profile.name)
                    .font(.largeTitle.bold())
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(profile.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                HStack(spacing: 8) {
                    ProfileBadge(text: "config", systemImage: "doc.text", isActive: profile.hasConfig)
                    ProfileBadge(text: "auth", systemImage: "key", isActive: profile.hasAuth)
                }
            }

            Spacer(minLength: 16)

            Button {
                store.revealProfile(profile)
            } label: {
                Label("Reveal", systemImage: "magnifyingglass")
            }
            .controlSize(.large)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }

    private var activeFilesCard: some View {
        SummaryCard(
            title: "Active Files",
            subtitle: store.activeSummary,
            systemImage: "checkmark.shield",
            tint: .green
        )
    }

    private func sourceCard(for profile: CodexProfile) -> some View {
        SummaryCard(
            title: "Profile Source",
            subtitle: profile.source == .folder ? "Folder profile" : "Loose ~/.codex files",
            systemImage: profile.source == .folder ? "folder" : "doc.on.doc",
            tint: .blue
        )
    }

    private func fileCard(for profile: CodexProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("Profile Files", systemImage: "tray.full")

            VStack(spacing: 10) {
                FileRow(title: "config.toml", systemImage: "doc.text", url: profile.configURL)
                Divider()
                FileRow(title: "auth.json", systemImage: "key", url: profile.authURL)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.08))
        }
    }

    private func switchCard(for profile: CodexProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionTitle("Switch Profile", systemImage: "arrow.triangle.2.circlepath")

            Toggle("Relaunch Codex after switch", isOn: $store.relaunchCodexAfterSwitch)
                .toggleStyle(.switch)

            HStack(spacing: 12) {
                Button {
                    store.switchToProfile(profile)
                } label: {
                    Label(
                        store.relaunchCodexAfterSwitch ? "Switch and Relaunch Codex" : "Switch to This Profile",
                        systemImage: store.relaunchCodexAfterSwitch ? "arrow.clockwise.circle" : "arrow.triangle.2.circlepath"
                    )
                    .frame(minWidth: 220)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    store.revealProfile(profile)
                } label: {
                    Label("Reveal Profile", systemImage: "folder")
                }
                .controlSize(.large)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.08))
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
        .background(Color(nsColor: .textBackgroundColor))
    }
}

private struct SidebarHeader: View {
    let profileCountText: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.14))

                Image(systemName: "slider.horizontal.3")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 2) {
                Text("Codex Switcher")
                    .font(.headline)
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
        HStack(spacing: 10) {
            ProfileIcon(profile: profile, size: 34)

            VStack(alignment: .leading, spacing: 5) {
                Text(profile.name)
                    .font(.headline)
                    .lineLimit(1)

                HStack(spacing: 8) {
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
                .fill(tint.opacity(0.14))

            Image(systemName: profile.source == .folder ? "folder.fill" : "doc.on.doc.fill")
                .font(.system(size: size * 0.44, weight: .semibold))
                .foregroundStyle(tint)
                .symbolRenderingMode(.hierarchical)
        }
        .frame(width: size, height: size)
    }
}

private struct SummaryCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title, systemImage: systemImage, tint: tint)

            Text(subtitle)
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.primary.opacity(0.08))
        }
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
                .font(.headline)
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
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(url == nil ? Color.secondary : Color.accentColor)
                .frame(width: 20)

            Text(title)
                .font(.callout.weight(.semibold))
                .frame(width: 94, alignment: .leading)

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
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
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
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct PathText: View {
    let url: URL?

    var body: some View {
        if let url {
            Text(url.path)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        } else {
            Text("Not included")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

private struct StatusBanner: View {
    let message: String

    private var tone: StatusTone {
        StatusTone(message: message)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: tone.systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(tone.tint)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(tone.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(tone.tint.opacity(0.18))
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
