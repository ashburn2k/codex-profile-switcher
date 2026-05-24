import AppKit
import SwiftUI

@main
struct CodexConfigSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ProfileStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .frame(
                    minWidth: 820,
                    idealWidth: 820,
                    maxWidth: 820,
                    minHeight: 460,
                    idealHeight: 460,
                    maxHeight: 460
                )
                .background(FixedWindowSize(size: NSSize(width: 820, height: 460)))
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 820, height: 460)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        DispatchQueue.main.async {
            self.showAvailableWindows(for: NSApp)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return true }
        showAvailableWindows(for: sender)
        return true
    }

    private func showAvailableWindows(for app: NSApplication) {
        app.unhide(nil)
        for window in app.windows {
            if window.isMiniaturized {
                window.deminiaturize(nil)
            }
            window.makeKeyAndOrderFront(nil)
        }
        app.activate(ignoringOtherApps: true)
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
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    final class Coordinator {
        var didApply = false
    }
}
