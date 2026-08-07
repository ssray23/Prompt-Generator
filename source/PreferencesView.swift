import SwiftUI
import AppKit

// MARK: - Preferences View
struct PreferencesView: View {
    @ObservedObject private var prefs = AppPreferences.shared

    @State private var selectedMode: PromptMode = .comprehensive
    // Local drafts — only written to disk when user hits Save
    @State private var draftTemplates: [PromptMode: String] = [:]
    @State private var showResetConfirm = false

    private var currentDraft: String {
        draftTemplates[selectedMode] ?? ""
    }

    // True if any draft differs from the currently saved template
    private var anyDirty: Bool {
        PromptMode.allCases.contains { mode in
            draftTemplates[mode] != prefs.template(for: mode)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            prefsTitleBar

            Divider()

            VStack(spacing: 10) {
                // Tab selector
                NativeSegmentedControl(
                    selection: Binding(
                        get: { PromptMode.allCases.firstIndex(of: selectedMode) ?? 0 },
                        set: { selectedMode = PromptMode.allCases[$0] }
                    ),
                    segments: PromptMode.allCases.map { $0.rawValue }
                )
                .frame(height: 24)

                // Info banner
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("Use {input} where you want the user's typed text to appear.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    // Show badge if this tab has a saved customisation
                    if prefs.isCustomized(for: selectedMode) {
                        Label("Customised", systemImage: "pencil.circle.fill")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            templateEditor

            Divider()
                .padding(.top, 10)

            footerBar
        }
        .frame(width: 700)
        .fixedSize(horizontal: false, vertical: true)
        .background(VisualEffectView(material: .windowBackground, blendingMode: .behindWindow)
            .ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .ignoresSafeArea(.all, edges: .top)
        .onAppear { loadDrafts() }
        // Reload drafts whenever the underlying prefs change (e.g. after reset)
        .onChange(of: prefs.detailedTemplate)  { _ in loadDrafts() }
        .onChange(of: prefs.shoppingTemplate)  { _ in loadDrafts() }
        .onChange(of: prefs.writingTemplate)   { _ in loadDrafts() }
        .onChange(of: prefs.analysisTemplate)  { _ in loadDrafts() }
        .confirmationDialog(
            "Reset all tabs to defaults?",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset All to Defaults", role: .destructive) {
                prefs.resetAllToDefaults()
                // loadDrafts() fires automatically via onChange above
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This deletes your saved customisations (UserPrompts.json) and restores all four tabs to the built-in factory prompts.")
        }
    }

    // MARK: - Title Bar
    private var prefsTitleBar: some View {
        HStack(spacing: 8) {
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                Text("Preferences")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
            }
            Spacer()
        }
        .frame(height: 28)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Template Editor Card
    private var templateEditor: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label("Prompt Template — \(selectedMode.rawValue)", systemImage: selectedMode.icon)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(currentDraft.count) chars")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            ZStack(alignment: .topLeading) {
                if let binding = Binding($draftTemplates[selectedMode]) {
                    Group {
                        if #available(macOS 13.0, *) {
                            TextEditor(text: binding)
                                .font(.system(size: 12, design: .monospaced))
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(minHeight: 320, maxHeight: 320)
                        } else {
                            TextEditor(text: binding)
                                .font(.system(size: 12, design: .monospaced))
                                .background(Color.clear)
                                .frame(minHeight: 320, maxHeight: 320)
                        }
                    }
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
        .padding(.horizontal, 20)
    }

    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack(spacing: 12) {
            // Reset All — deletes UserPrompts.json
            Button(action: { showResetConfirm = true }) {
                Label("Reset All to Defaults", systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.regular)
            .disabled(!prefs.hasUserOverrides && !anyDirty)

            Spacer()

            // Storage location hint
            if prefs.hasUserOverrides {
                HStack(spacing: 4) {
                    Image(systemName: "doc.badge.checkmark")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("UserPrompts.json")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Using factory defaults")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Save — creates / overwrites UserPrompts.json
            Button(action: saveAll) {
                Label(anyDirty ? "Save Changes" : "Saved", systemImage: anyDirty ? "square.and.arrow.down" : "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .disabled(!anyDirty)
        }
        .padding([.horizontal, .bottom], 20)
        .padding(.top, 14)
    }

    // MARK: - Helpers
    private func loadDrafts() {
        for mode in PromptMode.allCases {
            draftTemplates[mode] = prefs.template(for: mode)
        }
    }

    private func saveAll() {
        prefs.save(
            detailed:  draftTemplates[.comprehensive] ?? prefs.detailedTemplate,
            shopping:  draftTemplates[.shopping]      ?? prefs.shoppingTemplate,
            writing:   draftTemplates[.writing]       ?? prefs.writingTemplate,
            analysis:  draftTemplates[.analysis]      ?? prefs.analysisTemplate
        )
        HUDWindowController.shared.show(state: .success("Preferences Saved  ·  UserPrompts.json updated"))
    }
}
