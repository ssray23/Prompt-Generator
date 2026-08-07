import Cocoa
import SwiftUI

class QuickEntryPanel: NSPanel {
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    override func cancelOperation(_ sender: Any?) {
        QuickEntryWindowController.shared.closeWindow()
    }
}

class QuickEntryWindowController: NSWindowController, NSWindowDelegate {
    static let shared = QuickEntryWindowController()
    
    init() {
        let rect = NSRect(x: 0, y: 0, width: 660, height: 400)
        let window = QuickEntryPanel(
            contentRect: rect,
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
    
    func toggle() {
        if window?.isMiniaturized == true {
            window?.deminiaturize(nil)
            if #available(macOS 14.0, *) {
                NSApp.activate()
            } else {
                NSApp.activate(ignoringOtherApps: true)
            }
        } else if window?.isVisible == true {
            closeWindow()
        } else {
            show()
        }
    }
    
    private var isContentViewSetup = false
    
    func show() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
        
        if !isContentViewSetup {
            let view = QuickEntryView { [weak self] in
                self?.closeWindow()
            }
            
            // Use NSHostingView directly to bypass NSHostingController titlebar safe-area clipping bugs
            let hostingView = NSHostingView(rootView: view)
            
            // Force the view to calculate its exact intrinsic fixed height
            hostingView.setFrameSize(NSSize(width: 660, height: 1000))
            hostingView.layout()
            let fit = hostingView.fittingSize
            
            // Lock the window to perfectly match the SwiftUI fixed size to eliminate slack
            if fit.width > 0 && fit.height > 0 {
                self.window?.setContentSize(fit)
                self.window?.minSize = fit
                self.window?.maxSize = fit
            }
            
            self.window?.contentView = hostingView
            self.window?.center()
            self.isContentViewSetup = true
        }
        
        self.window?.makeKeyAndOrderFront(nil)
    }
    
    func closeWindow() {
        self.window?.orderOut(nil)
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closeWindow()
        return true
    }
}
