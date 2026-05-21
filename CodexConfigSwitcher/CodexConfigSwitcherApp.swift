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
                    idealWidth: 830,
                    minHeight: 500,
                    idealHeight: 540
                )
                .background(WindowInitialSize(size: NSSize(width: 830, height: 540)))
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 830, height: 540)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

private struct WindowInitialSize: NSViewRepresentable {
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
            window.setContentSize(size)
            window.center()
        }
    }

    final class Coordinator {
        var didApply = false
    }
}
