# Prompt Generator - Technical Documentation

This document explains the architecture and the role of each source file in the `Prompt Generator` application.

## Architecture Overview

The **Prompt Generator** is a hybrid macOS application that combines **AppKit** and **SwiftUI**. 
- **AppKit** is used for system-level integrations (global hotkeys, status bar menus, floating panels, window management, and native translucent text editors).
- **SwiftUI** is used for modern, declarative UI layout within the AppKit windows.

The app is designed as a quick-entry utility. It listens for a global hotkey (`Option + Command + P`), intercepts clipboard contents or user input, expands the input into a highly detailed prompt using the `PromptEngine`, and routes it directly to a web-based LLM provider (ChatGPT, Claude, Gemini, etc.).

---

## Source Files Breakdown

All source files are located in the `source/` directory. Below is a detailed explanation of each file's purpose:

### Entry Point & Application Lifecycle

* **`main.swift`**
  - The entry point of the application. It bootstraps the macOS app by calling `NSApplicationMain` or setting the delegate explicitly, bypassing the standard storyboard/xib lifecycle for a purely programmatic setup.

* **`AppDelegate.swift`**
  - Acts as the `NSApplicationDelegate`.
  - **Status Item**: Sets up the `NSStatusItem` (the icon in the macOS menu bar) and its dropdown menu.
  - **Menu Bar**: Dynamically builds the application's top menu bar (App Menu, Edit Menu for standard text shortcuts, and the custom File Menu for CSV export/import).
  - **Global Hotkey**: Uses Carbon APIs (`RegisterEventHotKey`) to register the `Option + Command + P` global shortcut.
  - **Auto-Start**: Integrates with `ServiceManagement` (`SMAppService`) to allow the app to launch automatically on login.

### Core Data & Logic

* **`PromptEngine.swift`**
  - The core business logic of the application.
  - Contains the `PromptMode` enum which defines the various templates (Comprehensive, Shopping, Writing, Analysis).
  - Contains the `LLMProvider` enum, which constructs the target URLs and defines the visual branding for various AI models.
  - The `expand(text:mode:)` function takes the user's raw input and weaves it into heavily engineered, persona-driven prompt templates with explicit instructions for the AI (e.g., Markdown tables, multiple-choice questionnaires).

* **`PromptSessionManager.swift`**
  - A centralized state manager (`ObservableObject` singleton) introduced to keep track of the user's input across different tabs.
  - Maintains a dictionary mapping each `PromptMode` to its current input string, ensuring text isn't overwritten when switching tabs.
  - Handles the **CSV Export** and **CSV Import** logic. It invokes `NSSavePanel` and `NSOpenPanel` as modal sheets (`beginSheetModal(for:)`) and parses/generates CSV data.

* **`PreferencesManager.swift`**
  - Handles reading and writing user settings to `UserDefaults`.
  - Manages custom prompt templates, default AI provider selections, and whether the app should launch at login.

### Main Interface (Quick Entry)

* **`QuickEntryWindowController.swift`**
  - Manages the floating `NSPanel` that acts as the main interface.
  - Configures the window to be a translucent, borderless, floating panel (`window.level = .floating`).
  - Wraps the SwiftUI `QuickEntryView` inside an `NSHostingView` and handles sizing constraints to ensure a tight, native fit without clipping.

* **`QuickEntryView.swift`**
  - The primary SwiftUI view containing the input text area, the live-updating prompt output, and action buttons.
  - Uses native AppKit wrappers (`TransparentMacEditor`, `NativeSegmentedControl`, `VisualEffectView`) via `NSViewRepresentable` to achieve pixel-perfect macOS translucency and text rendering that pure SwiftUI cannot easily replicate.
  - Handles the AppleScript bridging needed to open the final prompt directly in Google Chrome.

### Supplementary UI & Windows

* **`HUDWindowController.swift`**
  - Displays transient, floating notification banners (Heads-Up Display) at the bottom of the screen (e.g., "Copied Detailed Prompt", "Successfully exported CSV").
  - Self-dismisses after a short delay using animations.

* **`AnimationView.swift`**
  - Contains custom SwiftUI animation components (like checkmarks or sparkles) that are used within the HUD or the Quick Entry view to provide visual feedback to the user.

* **`PreferencesWindowController.swift`**
  - Manages the standard macOS Preferences window.
  - Uses a standard `NSWindow` (unlike the floating Quick Entry panel) to host the `PreferencesView`.

* **`PreferencesView.swift`**
  - A SwiftUI view providing the UI for configuring the app.
  - Allows users to edit the underlying templates for the PromptEngine, toggle launch at login, and customize their default LLM routing behavior.

---

## Data Flow (How an Export works)
1. The user clicks **File -> Export CSV...** in the menu bar.
2. `AppDelegate.swift` intercepts the click and calls `PromptSessionManager.shared.exportToCSV()`.
3. `PromptSessionManager` determines the active window (`QuickEntryWindowController.shared.window`) and drops an `NSSavePanel` over it.
4. The user selects a file name (defaulting to the current date/time) and saves.
5. The dictionary of inputs is flattened into a CSV string and saved to disk. A success message is fired via `HUDWindowController`.
