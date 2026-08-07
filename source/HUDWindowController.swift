import Cocoa
import SwiftUI

class HUDWindowController: NSWindowController {
    static let shared = HUDWindowController()
    private var dismissTimer: Timer?
    
    init() {
        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 60),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.center()
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show(state: HUDState, duration: TimeInterval = 2.0) {
        dismissTimer?.invalidate()
        
        let view = HUDView(state: state)
        let hostingView = NSHostingView(rootView: view)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        
        hostingView.setFrameSize(NSSize(width: 400, height: 100))
        hostingView.layout()
        let fit = hostingView.fittingSize
        
        self.window?.contentView = hostingView
        if fit.width > 0 && fit.height > 0 {
            self.window?.setContentSize(fit)
        }
        
        if let mainScreen = NSScreen.main {
            let screenRect = mainScreen.visibleFrame
            let windowSize = self.window?.frame.size ?? fit
            let x = screenRect.midX - (windowSize.width / 2)
            let y = screenRect.maxY - 120 // Positioned near top-center of screen
            self.window?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        self.window?.alphaValue = 0.0
        self.window?.makeKeyAndOrderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            self.window?.animator().alphaValue = 1.0
        }
        
        dismissTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    func dismiss() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            self.window?.animator().alphaValue = 0.0
        }, completionHandler: {
            self.window?.orderOut(nil)
        })
    }
}
