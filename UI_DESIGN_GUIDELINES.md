# macOS Native UI Design Guidelines

This document outlines the architectural and aesthetic design decisions made for the Prompt Generator app. It serves as a reference manual for building future macOS applications that strictly adhere to Apple's Human Interface Guidelines (HIG) while leveraging SwiftUI and AppKit.

## 1. Window & Architecture (AppKit + SwiftUI)
To achieve a truly native feel, do not rely purely on SwiftUI's `WindowGroup`. Hybrid architecture works best:
- **Utility Panels:** Use `NSPanel` with `.floating` window level so it stays above other windows.
- **Titlebars:** Use `styleMask: [.titled, .closable, .miniaturizable, .fullSizeContentView]` and set `window.titlebarAppearsTransparent = true`. This merges the standard traffic lights with your SwiftUI content flawlessly.
- **Dock Behavior:** If an app is a background utility (`LSUIElement = true`), use `.nonactivatingPanel` so clicking it doesn't interrupt the user's current app. If you want standard Dock behavior, avoid `.nonactivatingPanel` and leave `LSUIElement` disabled.

## 2. Spacing, Padding, and Alignment
macOS interfaces rely heavily on negative space and strict alignment:
- **Edge Padding:** Use `20pt` for horizontal edges and `14pt` to `20pt` for vertical edges (especially near the titlebar traffic lights).
- **Component Spacing:** Use `12pt` to `16pt` between major vertical components (e.g., in a `VStack`).
- **Alignment:** Strongly prefer `.leading` alignment for text and controls. Center alignment should be reserved for empty states or transient HUDs.

## 3. Typography
Avoid custom web fonts. Rely entirely on Apple's San Francisco (SF Pro) via standard semantic sizing:
- **Titles/Headers:** `.font(.title3.weight(.semibold))` or `.font(.headline)`
- **Body Text:** `.font(.body)`
- **Secondary Data / Labels:** `.font(.subheadline)` or `.font(.caption)` with `.foregroundColor(.secondary)`
- Let the system handle kerning, tracking, and optical sizing.

## 4. UI Widgets & Styling
Never attempt to fake native macOS controls using standard rounded rectangles and saturated colors. 
- **Segmented Controls:** SwiftUI's `Picker` can look web-like or overly vibrant. Wrap a pure `NSSegmentedControl` using `NSViewRepresentable` to guarantee the authentic Apple gray track and soft white highlight.
- **Dropdowns:** Use SwiftUI's `Menu` with `.menuStyle(.automatic)` or `.buttonStyle(.bordered)`. This creates the classic macOS push-button look with the double-arrow chevron. Avoid `.borderlessButton` unless in a specialized toolbar.
- **Buttons:** Use `.buttonStyle(.bordered)` or `.buttonStyle(.borderedProminent)`. Never use raw solid fills like `Color.blue`. Use `Color.accentColor` which adapts to the user's System Settings.
- **Text Areas:** Wrap `TextEditor` inside an `.overlay` using `Color(NSColor.separatorColor).opacity(0.4)` and a `RoundedRectangle(cornerRadius: 8)`. Use `Color(NSColor.textBackgroundColor)` for the fill.

## 5. Translucency & Materials (Glassmorphism)
macOS thrives on depth and materials. Never use solid flat gray for backgrounds.
- **Backgrounds:** Use SwiftUI's native `.ultraThinMaterial` or wrap an `NSVisualEffectView` (using materials like `.hudWindow`, `.sidebar`, or `.popover`). 
- **Rounding:** If placing a material inside a standard transparent `NSWindow`, explicitly apply `.clipShape(RoundedRectangle(cornerRadius: 10))` to perfectly match the top AppKit window corners.

## 6. Transient / Flashing Messages (Floating HUDs)
When displaying quick confirmation messages (like "Copied to Clipboard"):
- **Architecture:** Do not use `ZStack` overlays in your main view (they get clipped by the main window). Spawn a completely separate borderless `NSPanel` positioned dynamically over the screen.
- **Shape & Material:** Use a SwiftUI `Capsule()` layout. To avoid rendering bugs on transparent windows, use `Color(NSColor.windowBackgroundColor).opacity(0.95)` inside `.background(Capsule().fill(...))` instead of generic blurs.
- **Shadows:** A shadow of `Color.black.opacity(0.18)`, radius `10`, y: `5` provides perfect depth. **Crucial:** To prevent the shadow from being clipped into a hard rectangle by the `NSWindow` bounds, explicitly add `.padding(20)` to the SwiftUI view *outside* the shadow, and use `NSHostingView.fittingSize` to expand the physical `NSWindow` to wrap the padding.
- **Animations:** Use `NSAnimationContext.runAnimationGroup` to smoothly animate the `alphaValue` of the `NSWindow` itself (0.2s duration) rather than animating SwiftUI opacity.
