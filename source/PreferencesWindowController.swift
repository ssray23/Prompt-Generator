import Cocoa
import SwiftUI

class PreferencesWindowController: NSWindowController, NSWindowDelegate {
    static let shared = PreferencesWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        window.hasShadow = true
        window.backgroundColor = .clear
        window.isOpaque = false

        super.init(window: window)
        window.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isContentViewSetup = false

    func show() {
        if !isContentViewSetup {
            let view = PreferencesView()
            let hostingView = NSHostingView(rootView: view)

            hostingView.setFrameSize(NSSize(width: 700, height: 1000))
            hostingView.layout()
            let fit = hostingView.fittingSize

            if fit.width > 0 && fit.height > 0 {
                self.window?.setContentSize(fit)
                self.window?.minSize = fit
                self.window?.maxSize = fit
            }

            self.window?.contentView = hostingView
            self.window?.center()
            isContentViewSetup = true
        }

        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        self.window?.makeKeyAndOrderFront(nil)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        self.window?.orderOut(nil)
        return false
    }
}
