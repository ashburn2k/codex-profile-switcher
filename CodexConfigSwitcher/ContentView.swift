import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: ProfileStore
    @State private var selectedProfile: CodexProfile?

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
            List(store.profiles, selection: $selectedProfile) { profile in
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.name)
                        .font(.headline)

                    HStack(spacing: 8) {
                        ProfileBadge(text: profile.hasConfig ? "config" : "no config", isActive: profile.hasConfig)
                        ProfileBadge(text: profile.hasAuth ? "auth" : "no auth", isActive: profile.hasAuth)
                    }
                }
                .padding(.vertical, 6)
                .tag(profile)
            }
            .navigationTitle("Codex Profiles")

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Save Current As")
                    .font(.headline)

                TextField("Profile name", text: $store.newProfileName)
                    .textFieldStyle(.roundedBorder)

                Toggle("Include config.toml", isOn: $store.includeConfig)
                Toggle("Include auth.json", isOn: $store.includeAuth)

                Button {
                    store.saveCurrentAsProfile()
                } label: {
                    Label("Save Profile", systemImage: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var detail: some View {
        if let selectedProfile {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selectedProfile.name)
                        .font(.largeTitle.bold())

                    Text(selectedProfile.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Active Files")
                        .font(.headline)
                    Text(store.activeSummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                }

                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                    GridRow {
                        Text("Profile source")
                            .foregroundStyle(.secondary)
                        Text(selectedProfile.source == .folder ? "Folder profile" : "Loose ~/.codex files")
                    }

                    GridRow {
                        Text("config.toml")
                            .foregroundStyle(.secondary)
                        PathText(url: selectedProfile.configURL)
                    }

                    GridRow {
                        Text("auth.json")
                            .foregroundStyle(.secondary)
                        PathText(url: selectedProfile.authURL)
                    }
                }

                HStack {
                    Button {
                        store.switchToProfile(selectedProfile)
                    } label: {
                        Label("Switch to This Profile", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button {
                        store.revealProfile(selectedProfile)
                    } label: {
                        Label("Reveal", systemImage: "magnifyingglass")
                    }
                    .controlSize(.large)
                }

                Spacer()

                Text(store.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            .padding(28)
        } else {
            ContentUnavailableView(
                "No Profiles Found",
                systemImage: "switch.2",
                description: Text("Create a profile from your current Codex files or add folders under ~/.codex/profiles.")
            )
            .padding()
        }
    }
}

private struct ProfileBadge: View {
    let text: String
    let isActive: Bool

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isActive ? Color.accentColor.opacity(0.16) : Color.secondary.opacity(0.12))
            .foregroundStyle(isActive ? Color.accentColor : Color.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

private struct PathText: View {
    let url: URL?

    var body: some View {
        if let url {
            Text(url.path)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
        } else {
            Text("Not included")
                .foregroundStyle(.secondary)
        }
    }
}
