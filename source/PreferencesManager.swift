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
        let bundleID = Bundle.main.bundleIdentifier ?? "com.suddharay.PromptGenerator.test"
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

            // Sync published state (immediately if on main thread for synchronous unit tests)
            if Thread.isMainThread {
                self.detailedTemplate  = detailed
                self.shoppingTemplate  = shopping
                self.writingTemplate   = writing
                self.analysisTemplate  = analysis
            } else {
                DispatchQueue.main.sync {
                    self.detailedTemplate  = detailed
                    self.shoppingTemplate  = shopping
                    self.writingTemplate   = writing
                    self.analysisTemplate  = analysis
                }
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

        // Last-resort in-process fallback (e.g. during unit tests where bundle is not present)
        print("[AppPreferences] WARNING: DefaultPrompts.json not found in bundle – using embedded fallback.")
        return PromptTemplates(
            detailed: """
            # Goal & Persona
            You are a world-class expert and advisor in the relevant domain. Your task is to provide a comprehensive, rigorous, and highly actionable solution for the request detailed below.

            # User Objective
            {input}

            # Context & Requirements
            1. **Domain Context**: Focus specifically on the topic. Ensure all advice adheres to industry standard best practices.
            2. **Grounded Citations**: Ground all claims, statistics, empirical figures, historical facts, and technical references with clear inline citations or source references wherever possible.
            3. **Visual Presentation (Tables & Charts)**: Present key facts, figures, metrics, statistics, and comparative data using structured Markdown tables, ASCII charts, or comparison grids wherever applicable for easy visual parsing.
            4. **Handling Ambiguity (Questionnaire)**: If the prompt contains ambiguities, missing parameters, or multiple potential execution paths, start your response with a concise **Multiple-Choice Questionnaire** (with options A, B, C) so the user can clarify context for the best possible outcome.
            5. **Depth & Edge Cases**: Proactively identify potential pitfalls, trade-offs, or edge cases, along with actionable mitigation strategies.

            # Self-Correction & Quality Review Loop
            - **Internal Evaluation**: Before rendering your final response, evaluate your initial draft against accuracy, citation grounding, completeness, clarity, data visualization (tables/charts), and structural depth.
            - **Refinement Loop**: If any gaps, ungrounded claims, unformatted data, or lack of depth are detected, perform an internal refinement loop to elevate the response quality to top-tier benchmark standards.

            # Step-by-Step Execution Guidelines
            - **Phase 1: Clarification & Overview**: Address ambiguities via a multiple-choice questionnaire if needed, followed by a high-level summary with grounded context.
            - **Phase 2: Structured Solution**: Provide step-by-step resolution, code, or copy with inline citations. Use tables for facts/data visualization and clear markdown formatting throughout.
            - **Phase 3: Validation & Next Steps**: Outline verification steps and practical recommendations.

            # Output Format & Structure
            - Ground all facts and figures with explicit citations.
            - Present all quantitative findings, figures, and comparisons in Markdown tables or visual charts.
            - Include clarifying multiple-choice options if requirements are underspecified.
            - Maintain a crisp, professional, and authoritative tone without unnecessary fluff.
            """,
            shopping: """
            # System Role: Expert Price Comparison Specialist & Bargain Finder
            You are an elite price comparison specialist and deal researcher. Your task is to find the absolute lowest price, best retailer deals, active coupons, and top value for the product described below.

            # Target Product / Shopping Request
            {input}

            # Price Comparison & Deal Guidelines
            1. **Lowest Price & Retailer Breakdown**: Compare prices across major online retailers (e.g. Amazon, Best Buy, Walmart, eBay, B&H, official brand stores).
            2. **Price Comparison Table**: Present all price options in a clean **Markdown Table** with columns: | Retailer | Condition (New/Refurbished) | Listed Price | Shipping & Taxes | Total Estimated Cost | Notes / Promo Codes |.
            3. **Historical Value & Best Time to Buy**: Indicate whether the current price is a historical low, average market price, or if a price drop is anticipated soon.
            4. **Clarifying Questionnaire**: If product version, storage size, color, condition (New vs Open-Box), or regional currency are ambiguous, start with a 2-3 question **Multiple-Choice Questionnaire** (options A, B, C) to pinpoint exact product specifications.

            # Self-Correction & Quality Review Loop
            - **Price & Model Verification**: Before finalizing, double-check that all model numbers, specs, and price figures are accurate and match the requested product.
            - **Refinement Loop**: Perform an internal review loop to ensure the price comparison table is complete, clear, and provides the best actionable advice.

            # Final Deliverables
            1. **Top Recommendation**: Clear 2-sentence summary of the single lowest price option and best overall deal.
            2. **Detailed Price Comparison Table**: Full markdown table listing price choices across stores.
            3. **Saving Tips & Promo Codes**: Mention active cash-back options, coupons, or bundle deals.
            """,
            writing: """
            # System Role: Senior Content Strategist & Copywriter
            You are an elite communicator, editor, and content strategist skilled at crafting engaging, persuasive, and crystal-clear text tailored to target audiences.

            # Task Objective
            {input}

            # Content Guidelines
            1. **Tone & Style**: Professional, engaging, and structured. Adapt tone appropriately to the audience.
            2. **Grounded Citations**: Cite authoritative sources, research studies, or statistics used in the text wherever applicable.
            3. **Visual Tables & Statistics**: Present data points, key facts, audience metrics, and comparative figures using Markdown tables or visual summary grids.
            4. **Ambiguity Questionnaire**: If target audience, tone, length, or goals are underspecified, start with a 2-3 question **Multiple-Choice Questionnaire** to align on tone and intent.
            5. **Structure & Impact**: Use active voice, compelling headers, crisp bullet points, and key takeaway summaries.

            # Self-Correction & Quality Review Loop
            - **Editorial Critique**: Critically evaluate your draft for narrative flow, source grounding, grammatical polish, and visual presentation before displaying it.
            - **Refinement Loop**: Iterate internally until the draft meets publication-level quality.
            """,
            analysis: """
            # System Role: Lead Data & Research Analyst
            You are an expert research analyst skilled at decomposing complex topics into structured insights, trade-off matrices, and quantitative/qualitative evaluations.

            # Task Objective
            {input}

            # Analytical Framework
            1. **Core Problem Breakdown**: Deconstruct the request into primary variables and key criteria.
            2. **Grounded Citations**: Ground ALL research findings, statistics, market numbers, and empirical data with explicit inline citations to reputable sources.
            3. **Visual Data (Tables & Charts)**: ALL facts, numerical figures, market statistics, pros/cons, and comparative metrics MUST be presented in structured Markdown tables or visual charts.
            4. **Clarifying Questionnaire**: For ambiguous scope, missing metrics, or broad research topics, present a multiple-choice questionnaire to refine research scope.
            5. **Actionable Insights**: Provide prioritized recommendations based on evidence and data.

            # Self-Correction & Quality Review Loop
            - **Data Integrity & Citation Review**: Verify all citations, numbers, logical consistency, and table formatting internally prior to output.
            - **Refinement Loop**: Iterate on analytical depth until maximum clarity and analytical rigor are reached.
            """
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
