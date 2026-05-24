import Foundation

struct CodexProfile: Identifiable, Hashable {
    enum Source: String {
        case folder
        case looseFiles
    }

    let id: String
    let name: String
    let source: Source
    let configURL: URL?
    let authURL: URL?
    let appSettingsURL: URL?
    let folderURL: URL?

    var hasConfig: Bool {
        configURL != nil
    }

    var hasAuth: Bool {
        authURL != nil
    }

    var hasAppSettings: Bool {
        appSettingsURL != nil
    }

    var detail: String {
        switch source {
        case .folder:
            return folderURL?.path ?? "Profile folder"
        case .looseFiles:
            return "Loose files in ~/.codex"
        }
    }
}
