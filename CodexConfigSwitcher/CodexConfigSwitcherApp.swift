import AppKit
import SwiftUI

@main
struct CodexConfigSwitcherApp: App {
    @StateObject private var store = ProfileStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(
                    minWidth: 800,
                    idealWidth: 800,
                    maxWidth: 800,
                    minHeight: 520,
                    idealHeight: 520,
                    maxHeight: 520
                )
                .background(FixedWindowSize(size: NSSize(width: 800, height: 520)))
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 520)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

private struct FixedWindowSize: NSViewRepresentable {
    let size: NSSize

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        scheduleApply(from: view, coordinator: context.coordinator)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        scheduleApply(from: view, coordinator: context.coordinator)
    }

    private func scheduleApply(from view: NSView, coordinator: Coordinator) {
        DispatchQueue.main.async {
            guard !coordinator.didApply, let window = view.window else { return }
            coordinator.didApply = true
            let lockedFrameSize = window.frameRect(forContentRect: NSRect(origin: .zero, size: size)).size
            window.minSize = lockedFrameSize
            window.maxSize = lockedFrameSize
            window.styleMask.remove(.resizable)
            window.setContentSize(size)
            window.center()
        }
    }

    final class Coordinator {
        var didApply = false
    }
}
