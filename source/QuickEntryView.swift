import SwiftUI
import AppKit

// MARK: - Native Transparent macOS Text Editor Wrapper
struct TransparentMacEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont = NSFont.systemFont(ofSize: 14, weight: .regular)
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        let textView = NSTextView()
        textView.autoresizingMask = [.width]
        textView.isRichText = false
        textView.font = font
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.insertionPointColor = NSColor.controlAccentColor
        textView.delegate = context.coordinator
        textView.allowsUndo = true
        
        // Zero out internal padding for pixel-perfect placeholder alignment
        textView.textContainerInset = NSSize(width: 0, height: 0)
        textView.textContainer?.lineFragmentPadding = 0
        
        scrollView.documentView = textView
        
        // Focus text view immediately
        DispatchQueue.main.async {
            textView.window?.makeFirstResponder(textView)
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            if textView.string != text {
                textView.string = text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TransparentMacEditor
        
        init(_ parent: TransparentMacEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            if let textView = notification.object as? NSTextView {
                self.parent.text = textView.string
            }
        }
    }
}

// MARK: - Visual Effect View for Native macOS Translucency
struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// MARK: - Native AppKit Segmented Control
struct NativeSegmentedControl: NSViewRepresentable {
    @Binding var selection: Int
    var segments: [String]
    
    func makeNSView(context: Context) -> NSSegmentedControl {
        let control = NSSegmentedControl(labels: segments, trackingMode: .selectOne, target: context.coordinator, action: #selector(Coordinator.onChange(_:)))
        control.segmentDistribution = .fillProportionally
        control.selectedSegment = selection
        return control
    }
    
    func updateNSView(_ nsView: NSSegmentedControl, context: Context) {
        if nsView.selectedSegment != selection {
            nsView.selectedSegment = selection
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var parent: NativeSegmentedControl
        
        init(_ parent: NativeSegmentedControl) {
            self.parent = parent
        }
        
        @objc func onChange(_ sender: NSSegmentedControl) {
            parent.selection = sender.selectedSegment
        }
    }
}

// MARK: - Main Solid Apple-Style Quick Entry View
struct QuickEntryView: View {
    @State private var rawText: String = ""
    @State private var selectedMode: PromptMode = .comprehensive
    @State private var isCopied: Bool = false
    // Observing AppPreferences ensures expandedPrompt recomputes immediately
    // after the user saves changes in the Preferences window.
    @ObservedObject private var prefs = AppPreferences.shared
    
    let onDismiss: () -> Void
    
    private var expandedPrompt: String {
        PromptEngine.expand(text: rawText, mode: selectedMode)
    }
    
    private var cardFillColor: Color {
        Color.primary.opacity(0.04)
    }
    
    private var cardStrokeColor: Color {
        Color.primary.opacity(0.08)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Titlebar Header Bar
            headerBar
            
            Divider()
            
            // Main Content Body (HIG 20pt padding)
            VStack(spacing: 14) {
                // Segmented Mode Selector Bar
                modeSegmentedControl
                
                // Light Gray Grouped Inset Input Field
                groupedInputCard
                
                // Light Gray Grouped Inset Output Field
                groupedOutputCard
            }
            .padding([.horizontal, .bottom], 20)
            .padding(.top, 14) // Slightly tighter near the divider
            
            Divider()
            
            // Bottom Action Footer Bar (HIG 20pt padding)
            footerActionBar
        }
        .frame(width: 660)
        .fixedSize(horizontal: false, vertical: true)
        .background(VisualEffectView().ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .ignoresSafeArea(.all, edges: .top)
    }
    
    // MARK: - Header Bar (Aligned vertically on top titlebar line with traffic light buttons)
    private var headerBar: some View {
        HStack(spacing: 8) {
            Spacer()
            
            // Centered App Title with SF Symbol & Hotkey Badge
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Prompt Generator")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .frame(height: 28) // Titlebar height
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
    
    // MARK: - Mode Segmented Control
    private var modeSegmentedControl: some View {
        NativeSegmentedControl(
            selection: Binding(
                get: { PromptMode.allCases.firstIndex(of: selectedMode) ?? 0 },
                set: { selectedMode = PromptMode.allCases[$0] }
            ),
            segments: PromptMode.allCases.map { $0.rawValue }
        )
        .frame(height: 24)
    }
    
    // MARK: - Grouped Inset Input Field
    private var groupedInputCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Input Thought")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !rawText.isEmpty {
                    Button(action: { rawText = "" }) {
                        Text("Clear")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary.opacity(0.5))
                }
                
                Button(action: pasteFromClipboard) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste Clipboard")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
            
            // Light Gray Inset Form Container (macOS System Settings Grouped Card Style)
            ZStack(alignment: .topLeading) {
                TransparentMacEditor(text: $rawText, font: NSFont.systemFont(ofSize: 14, weight: .regular))
                    .frame(height: 70)
                
                if rawText.isEmpty {
                    Text(selectedMode.inputPlaceholder)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color(NSColor.placeholderTextColor))
                        .allowsHitTesting(false)
                }
            }
            .padding(10)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Grouped Inset Output Field
    private var groupedOutputCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Converted Detailed Prompt")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !expandedPrompt.isEmpty {
                    Text("\(expandedPrompt.count) chars  •  \(expandedPrompt.components(separatedBy: .whitespacesAndNewlines).filter({ !$0.isEmpty }).count) words")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            
            // Light Gray Inset Preview Container
            ScrollView {
                VStack(alignment: .leading) {
                    if expandedPrompt.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 10) {
                                Image(systemName: selectedMode.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(NSColor.tertiaryLabelColor))
                                
                                Text(selectedMode.outputDescription)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color(NSColor.secondaryLabelColor))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                            .padding(.vertical, 24)
                            Spacer()
                        }
                    } else {
                        Text(expandedPrompt)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .padding(12)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 165)
            .background(Color(NSColor.textBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Footer Action Bar (HIG 20pt padding)
    private var footerActionBar: some View {
        HStack(spacing: 12) {
            // Primary Quick Copy Button
            Button(action: copyPromptToClipboard) {
                Label(isCopied ? "Copied Prompt" : "Quick Copy Prompt", systemImage: isCopied ? "checkmark" : "doc.on.doc.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(expandedPrompt.isEmpty)
            
            Spacer()
            
            // Native AI Provider Menu
            Menu {
                // Open all providers at once
                Button(action: openAllProviders) {
                    Label("Open in All (5 tabs)", systemImage: "square.stack.fill")
                }

                Divider()

                ForEach(LLMProvider.allCases) { provider in
                    Button(action: {
                        openProvider(provider)
                    }) {
                        Label(provider.rawValue, systemImage: provider.iconName)
                    }
                }
            } label: {
                Text("Open in AI...")
            }
            .menuStyle(.automatic)
            .fixedSize()
            .disabled(expandedPrompt.isEmpty)
        }
        .padding([.horizontal, .bottom], 20)
        .padding(.top, 14)
    }
    
    // MARK: - Action Handlers
    private func copyPromptToClipboard() {
        guard !expandedPrompt.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(expandedPrompt, forType: .string)
        
        isCopied = true
        
        HUDWindowController.shared.show(state: .success("Copied Detailed Prompt"))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCopied = false
        }
    }
    
    private func openProvider(_ provider: LLMProvider) {
        guard !expandedPrompt.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(expandedPrompt, forType: .string)
        
        if let url = provider.targetURL(for: expandedPrompt) {
            let script = """
            if application "Google Chrome" is running then
                tell application "Google Chrome"
                    activate
                    if (count every window) = 0 then
                        make new window
                        set URL of active tab of front window to "\(url.absoluteString)"
                    else
                        tell front window
                            make new tab with properties {URL:"\(url.absoluteString)"}
                        end tell
                    end if
                end tell
            else
                tell application "Google Chrome"
                    activate
                    open location "\(url.absoluteString)"
                end tell
            end if
            """
            
            var error: NSDictionary?
            let appleScript = NSAppleScript(source: script)
            let success = appleScript?.executeAndReturnError(&error) != nil && error == nil
            
            if !success {
                // Fallback to default browser
                NSWorkspace.shared.open(url)
            }
            
            HUDWindowController.shared.show(state: .success("Prompt Copied! Press ⌘V in \(provider.rawValue)"))
        }
    }
    
    private func openAllProviders() {
        guard !expandedPrompt.isEmpty else { return }

        // Copy prompt to clipboard once for all providers
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(expandedPrompt, forType: .string)

        let providers = LLMProvider.allCases

        // Build one AppleScript that opens all URLs as new tabs in sequence,
        // so Chrome only needs to be triggered once (much more reliable than 5 separate calls).
        let urlStrings = providers.compactMap { $0.targetURL(for: expandedPrompt)?.absoluteString }
        guard !urlStrings.isEmpty else { return }

        // Build "make new tab" commands for tabs 2-N; the first URL goes into a new window if needed.
        let tabCommands = urlStrings.dropFirst().map {
            "make new tab with properties {URL:\"\($0)\"} in front window"
        }.joined(separator: "\n                    ")

        let firstURL = urlStrings[0]
        let script = """
        if application "Google Chrome" is running then
            tell application "Google Chrome"
                activate
                if (count every window) = 0 then
                    make new window
                    set URL of active tab of front window to "\(firstURL)"
                else
                    make new tab with properties {URL:"\(firstURL)"} in front window
                end if
                \(tabCommands)
            end tell
        else
            tell application "Google Chrome"
                activate
                open location "\(firstURL)"
            end tell
        end if
        """

        var error: NSDictionary?
        let appleScript = NSAppleScript(source: script)
        let success = appleScript?.executeAndReturnError(&error) != nil && error == nil

        if !success {
            // Fallback: open each URL in the default browser
            for provider in providers {
                if let url = provider.targetURL(for: expandedPrompt) {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        HUDWindowController.shared.show(state: .success("Opened all 5 AI tabs  ·  Prompt in clipboard"))
    }

    private func pasteFromClipboard() {
        if let clipString = NSPasteboard.general.string(forType: .string),
           !clipString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            rawText = clipString
        }
    }
}
