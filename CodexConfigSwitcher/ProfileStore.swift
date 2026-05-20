import Foundation
import SwiftUI

@MainActor
final class ProfileStore: ObservableObject {
    @Published private(set) var profiles: [CodexProfile] = []
    @Published private(set) var activeSummary = "Not checked yet"
    @Published var statusMessage = ""
    @Published var newProfileName = ""
    @Published var includeConfig = true
    @Published var includeAuth = true

    private let fileManager = FileManager.default
    private let codexURL: URL
    private let profilesURL: URL
    private let backupsURL: URL

    init() {
        let home = fileManager.homeDirectoryForCurrentUser
        codexURL = home.appendingPathComponent(".codex", isDirectory: true)
        profilesURL = codexURL.appendingPathComponent("profiles", isDirectory: true)
        backupsURL = codexURL.appendingPathComponent("profile-switcher-backups", isDirectory: true)
        refresh()
    }

    var configURL: URL {
        codexURL.appendingPathComponent("config.toml")
    }

    var authURL: URL {
        codexURL.appendingPathComponent("auth.json")
    }

    func refresh() {
        do {
            try ensureDirectories()
            profiles = try discoverProfiles()
            activeSummary = activeFileSummary()
            if statusMessage.isEmpty {
                statusMessage = "Loaded \(profiles.count) profile\(profiles.count == 1 ? "" : "s")."
            }
        } catch {
            statusMessage = "Refresh failed: \(error.localizedDescription)"
        }
    }

    func switchToProfile(_ profile: CodexProfile) {
        do {
            try ensureDirectories()
            let stamp = timestamp()
            let backupFolder = backupsURL.appendingPathComponent(stamp, isDirectory: true)
            try fileManager.createDirectory(at: backupFolder, withIntermediateDirectories: true)

            try backupActiveFiles(to: backupFolder)
            try install(profile.configURL, to: configURL)
            try install(profile.authURL, to: authURL)

            statusMessage = "Switched to \(profile.name). Backup: \(backupFolder.lastPathComponent)"
            refresh()
        } catch {
            statusMessage = "Switch failed: \(error.localizedDescription)"
        }
    }

    func saveCurrentAsProfile() {
        let name = sanitizedProfileName(newProfileName)
        guard !name.isEmpty else {
            statusMessage = "Enter a profile name first."
            return
        }
        guard includeConfig || includeAuth else {
            statusMessage = "Choose config.toml, auth.json, or both."
            return
        }

        do {
            try ensureDirectories()
            let folder = profilesURL.appendingPathComponent(name, isDirectory: true)
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)

            if includeConfig {
                try copyIfExists(configURL, to: folder.appendingPathComponent("config.toml"))
            }

            if includeAuth {
                try copyIfExists(authURL, to: folder.appendingPathComponent("auth.json"))
            }

            newProfileName = ""
            statusMessage = "Saved current files as \(name)."
            refresh()
        } catch {
            statusMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    func revealCodexFolder() {
        NSWorkspace.shared.activateFileViewerSelecting([codexURL])
    }

    func revealProfile(_ profile: CodexProfile) {
        let url = profile.folderURL ?? profile.configURL ?? profile.authURL ?? codexURL
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func ensureDirectories() throws {
        try fileManager.createDirectory(at: codexURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: profilesURL, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: backupsURL, withIntermediateDirectories: true)
    }

    private func discoverProfiles() throws -> [CodexProfile] {
        var discovered: [CodexProfile] = []
        var seenNames = Set<String>()

        if fileManager.fileExists(atPath: profilesURL.path) {
            let folders = try fileManager.contentsOfDirectory(
                at: profilesURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            for folder in folders.sorted(by: { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }) {
                let values = try folder.resourceValues(forKeys: [.isDirectoryKey])
                guard values.isDirectory == true else { continue }

                let config = existingFile(folder.appendingPathComponent("config.toml"))
                let auth = existingFile(folder.appendingPathComponent("auth.json"))
                guard config != nil || auth != nil else { continue }

                let name = folder.lastPathComponent
                seenNames.insert(name.lowercased())
                discovered.append(CodexProfile(
                    id: "folder-\(name)",
                    name: name,
                    source: .folder,
                    configURL: config,
                    authURL: auth,
                    folderURL: folder
                ))
            }
        }

        let loose = try discoverLooseProfiles(excluding: seenNames)
        discovered.append(contentsOf: loose)
        return discovered
    }

    private func discoverLooseProfiles(excluding existingNames: Set<String>) throws -> [CodexProfile] {
        let files = try fileManager.contentsOfDirectory(
            at: codexURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )

        var configs: [String: URL] = [:]
        var auths: [String: URL] = [:]

        for file in files {
            let name = file.lastPathComponent
            if name.hasPrefix("config-"), name.hasSuffix(".toml") {
                configs[String(name.dropFirst("config-".count).dropLast(".toml".count))] = file
            } else if name.hasPrefix("auth-"), name.hasSuffix(".json") {
                auths[String(name.dropFirst("auth-".count).dropLast(".json".count))] = file
            }
        }

        return Set(configs.keys).union(auths.keys)
            .filter { !existingNames.contains($0.lowercased()) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .map { key in
                CodexProfile(
                    id: "loose-\(key)",
                    name: key,
                    source: .looseFiles,
                    configURL: configs[key],
                    authURL: auths[key],
                    folderURL: nil
                )
            }
    }

    private func existingFile(_ url: URL) -> URL? {
        fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func backupActiveFiles(to backupFolder: URL) throws {
        try copyIfExists(configURL, to: backupFolder.appendingPathComponent("config.toml"))
        try copyIfExists(authURL, to: backupFolder.appendingPathComponent("auth.json"))
    }

    private func install(_ source: URL?, to destination: URL) throws {
        guard let source else { return }
        let temporary = destination.deletingLastPathComponent()
            .appendingPathComponent(".\(destination.lastPathComponent).switcher-\(UUID().uuidString)")
        try copyReplacing(source, to: temporary)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: temporary, to: destination)
    }

    private func copyIfExists(_ source: URL, to destination: URL) throws {
        guard fileManager.fileExists(atPath: source.path) else { return }
        try copyReplacing(source, to: destination)
    }

    private func copyReplacing(_ source: URL, to destination: URL) throws {
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: source, to: destination)
    }

    private func activeFileSummary() -> String {
        let config = fileSummary(configURL)
        let auth = fileSummary(authURL)
        return "config.toml: \(config) | auth.json: \(auth)"
    }

    private func fileSummary(_ url: URL) -> String {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path) else {
            return "missing"
        }

        let size = attributes[.size] as? NSNumber
        let modified = attributes[.modificationDate] as? Date
        let byteCount = ByteCountFormatter.string(fromByteCount: size?.int64Value ?? 0, countStyle: .file)

        if let modified {
            return "\(byteCount), \(modified.formatted(date: .abbreviated, time: .shortened))"
        }

        return byteCount
    }

    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
    }

    private func sanitizedProfileName(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
    }
}
