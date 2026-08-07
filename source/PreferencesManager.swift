import Foundation
import Combine

// MARK: - Prompt Templates Model (Codable for JSON)
public struct PromptTemplates: Codable {
    public var detailed:  String
    public var shopping:  String
    public var writing:   String
    public var analysis:  String
}

// MARK: - AppPreferences
/// Manages prompt templates using a two-layer file pattern:
///
/// Layer 1 (read-only): <App>.app/Contents/Resources/DefaultPrompts.json
///   – Shipped with the app. Never modified at runtime. Acts as factory defaults.
///
/// Layer 2 (read/write): ~/Library/Application Support/<BundleID>/UserPrompts.json
///   – Created only when the user saves a customisation.
///   – Deleted entirely when the user resets all tabs to defaults.
///   – If absent, the app transparently falls back to Layer 1.
public class AppPreferences: ObservableObject {
    public static let shared = AppPreferences()

    // MARK: - Published live templates (reflects current effective values)
    @Published public var detailedTemplate:  String = ""
    @Published public var shoppingTemplate:  String = ""
    @Published public var writingTemplate:   String = ""
    @Published public var analysisTemplate:  String = ""

    // MARK: - Private state
    private var bundleTemplates: PromptTemplates?

    private var userFileURL: URL? {
        guard let bundleID = Bundle.main.bundleIdentifier else { return nil }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return appSupport?
            .appendingPathComponent(bundleID, isDirectory: true)
            .appendingPathComponent("UserPrompts.json")
    }

    // MARK: - Init
    private init() {
        reload()
    }

    // MARK: - Load (called on init and after reset)
    /// Loads templates: user file first, then bundle defaults.
    public func reload() {
        let bundle = loadBundleTemplates()
        bundleTemplates = bundle

        // Try user file; fall back to bundle for any missing key
        if let user = loadUserTemplates() {
            detailedTemplate  = user.detailed.isEmpty  ? bundle.detailed  : user.detailed
            shoppingTemplate  = user.shopping.isEmpty  ? bundle.shopping  : user.shopping
            writingTemplate   = user.writing.isEmpty   ? bundle.writing   : user.writing
            analysisTemplate  = user.analysis.isEmpty  ? bundle.analysis  : user.analysis
        } else {
            // No user file → use bundle defaults verbatim
            detailedTemplate  = bundle.detailed
            shoppingTemplate  = bundle.shopping
            writingTemplate   = bundle.writing
            analysisTemplate  = bundle.analysis
        }
    }

    // MARK: - Save
    /// Writes all four templates to UserPrompts.json (creates directory if needed).
    /// Call this when the user explicitly hits "Save".
    public func save(detailed: String, shopping: String, writing: String, analysis: String) {
        let templates = PromptTemplates(
            detailed:  detailed,
            shopping:  shopping,
            writing:   writing,
            analysis:  analysis
        )

        guard let url = userFileURL else { return }

        do {
            // Ensure ~/Library/Application Support/<BundleID>/ exists
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(templates)
            try data.write(to: url, options: .atomic)

            // Sync published state
            DispatchQueue.main.async {
                self.detailedTemplate  = detailed
                self.shoppingTemplate  = shopping
                self.writingTemplate   = writing
                self.analysisTemplate  = analysis
            }
        } catch {
            print("[AppPreferences] Failed to save UserPrompts.json: \(error)")
        }
    }

    // MARK: - Reset All to Defaults
    /// Deletes UserPrompts.json entirely and reloads from bundle defaults.
    public func resetAllToDefaults() {
        if let url = userFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        reload()
    }

    // MARK: - Accessors by PromptMode
    public func template(for mode: PromptMode) -> String {
        switch mode {
        case .comprehensive: return detailedTemplate
        case .shopping:      return shoppingTemplate
        case .writing:       return writingTemplate
        case .analysis:      return analysisTemplate
        }
    }

    /// Returns the factory default for a given mode (from the bundle JSON).
    public func bundleDefault(for mode: PromptMode) -> String {
        guard let b = bundleTemplates else { return "" }
        switch mode {
        case .comprehensive: return b.detailed
        case .shopping:      return b.shopping
        case .writing:       return b.writing
        case .analysis:      return b.analysis
        }
    }

    /// True if the user has a non-default override saved for the given mode.
    public func isCustomized(for mode: PromptMode) -> Bool {
        template(for: mode) != bundleDefault(for: mode)
    }

    /// True if UserPrompts.json exists on disk (any override is active).
    public var hasUserOverrides: Bool {
        guard let url = userFileURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }

    // MARK: - Private Helpers

    private func loadBundleTemplates() -> PromptTemplates {
        // Locate DefaultPrompts.json inside the app bundle's Resources folder
        if let url = Bundle.main.url(forResource: "DefaultPrompts", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let templates = try? JSONDecoder().decode(PromptTemplates.self, from: data) {
            return templates
        }

        // Last-resort in-process fallback (should never be needed if build.sh is correct)
        print("[AppPreferences] WARNING: DefaultPrompts.json not found in bundle – using embedded fallback.")
        return PromptTemplates(
            detailed:  "# Detailed Prompt\n{input}",
            shopping:  "# Shopping Prompt\n{input}",
            writing:   "# Writing Prompt\n{input}",
            analysis:  "# Analysis Prompt\n{input}"
        )
    }

    private func loadUserTemplates() -> PromptTemplates? {
        guard let url = userFileURL,
              FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let templates = try? JSONDecoder().decode(PromptTemplates.self, from: data)
        else { return nil }
        return templates
    }
}
