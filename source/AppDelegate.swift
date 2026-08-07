import Cocoa
import Carbon
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    var hotKeyRef: EventHotKeyRef?
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenu()
        setupStatusItem()
        registerGlobalHotKey()
        
        if #available(macOS 13.0, *) {
            do {
                if SMAppService.mainApp.status == .notRegistered {
                    try SMAppService.mainApp.register()
                    print("Successfully registered Prompt Generator for login auto-start")
                }
            } catch {
                print("Failed to register for login: \(error)")
            }
        }
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let image = NSImage(systemSymbolName: "wand.and.stars", accessibilityDescription: "Prompt Generator") {
                button.image = image
            } else if let fallbackImage = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Prompt Generator") {
                button.image = fallbackImage
            }
            button.target = self
            button.action = #selector(statusItemClicked)
            button.toolTip = "Prompt Generator (Opt + Cmd + P)"
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Toggle Prompt Generator (⌥⌘P)", action: #selector(toggleQuickEntry), keyEquivalent: "p"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Prompt Generator", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func statusItemClicked() {
        QuickEntryWindowController.shared.toggle()
    }
    
    @objc func toggleQuickEntry() {
        QuickEntryWindowController.shared.toggle()
    }
    
    private func setupMenu() {
        let mainMenu = NSMenu()
        NSApp.mainMenu = mainMenu
        
        // App Menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        
        // Edit Menu (Essential for Cmd+C, Cmd+V, Cmd+A in NSPanel text views)
        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
    }
    
    func registerGlobalHotKey() {
        var hotKeyId = EventHotKeyID()
        hotKeyId.signature = OSType(fourCharCode("PRMP"))
        hotKeyId.id = 1
        
        // Option + Command + P
        // kVK_ANSI_P = 0x23 (35)
        let modifierFlags = UInt32(cmdKey | optionKey)
        let keyCode = UInt32(kVK_ANSI_P)
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let appTarget = GetApplicationEventTarget()
        
        // Install event handler
        let handlerStatus = InstallEventHandler(appTarget, { (nextHandler, theEvent, userData) -> OSStatus in
            NotificationCenter.default.post(name: NSNotification.Name("PromptGeneratorHotKeyPressed"), object: nil)
            return noErr
        }, 1, &eventType, nil, nil)
        
        print("InstallEventHandler status: \(handlerStatus)")
        
        // Register hotkey
        let registerStatus = RegisterEventHotKey(keyCode, modifierFlags, hotKeyId, appTarget, 0, &hotKeyRef)
        print("RegisterEventHotKey status: \(registerStatus)")
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleHotKey), name: NSNotification.Name("PromptGeneratorHotKeyPressed"), object: nil)
    }
    
    @objc func handleHotKey() {
        QuickEntryWindowController.shared.toggle()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            QuickEntryWindowController.shared.show()
        }
        return true
    }
    
    private func fourCharCode(_ string: String) -> Int {
        var result: Int = 0
        for char in string.utf16 {
            result = (result << 8) + Int(char)
        }
        return result
    }
}
