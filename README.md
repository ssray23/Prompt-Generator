# Prompt Generator

A blazing-fast, floating macOS utility panel built to supercharge your AI workflows. It intercepts your clipboard and instantly formats text into heavily engineered, high-density prompts for your favorite AI providers.

## Features
- **Global Hotkey**: Press `Option + Command + P` anywhere in macOS to instantly summon the floating panel.
- **Auto-Formatting**: Automatically expands your ideas into highly structured, persona-driven prompts with explicit constraints (Markdown, tables, citations, etc.).
- **Multiple Modes**: Support for Comprehensive, Shopping, Writing, and Analysis prompts.
- **Provider Hand-off**: Instantly routes your engineered prompt to ChatGPT, Claude, Gemini, Perplexity, or Grok in a new Chrome tab.
- **CSV Import/Export**: Save and load your inputs across all tabs seamlessly via the File menu.
- **Native macOS Design**: Pure AppKit UI with SwiftUI components, translucent vibrancy, rounded corners, and macOS native dropdowns—no Electron overhead.

## Building & Installation
Run the included build script to compile the Swift sources natively, generate the app icon, and install the `.app` directly to your `~/Applications` folder.

```bash
./build.sh
```

After building, you can find the app at `~/Applications/Prompt Generator.app`.

## Tech Stack
- Swift 5 (AppKit + SwiftUI)
- No external dependencies
- Minimal resource footprint (zero background CPU usage when idle)

