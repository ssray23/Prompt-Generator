import Foundation
import SwiftUI

public enum PromptMode: String, CaseIterable, Identifiable {
    case comprehensive = "Detailed"
    case shopping = "Shopping"
    case writing = "Writing"
    case analysis = "Analysis"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .comprehensive: return "sparkles"
        case .shopping: return "bag.fill"
        case .writing: return "doc.text.fill"
        case .analysis: return "chart.bar.fill"
        }
    }
    
    public var inputPlaceholder: String {
        switch self {
        case .comprehensive:
            return "Enter any broad idea, task, or question... (e.g. 'Plan a 5-day trip to Tokyo on a budget')"
        case .shopping:
            return "Enter product name, model, or deal request... (e.g. 'Sony WH-1000XM5 headphones' or 'MacBook Air M3')"
        case .writing:
            return "Enter email brief, article topic, or copy draft... (e.g. 'Polite email requesting a promotion')"
        case .analysis:
            return "Enter research topic, dataset, or comparison... (e.g. 'Compare PostgreSQL vs MongoDB for analytics')"
        }
    }
    
    public var outputDescription: String {
        switch self {
        case .comprehensive:
            return "Expands into a structured master prompt with persona, domain rules, Markdown tables/charts, multiple-choice questionnaire & self-review loop."
        case .shopping:
            return "Expands into an e-commerce price hunter prompt with store comparison table, historical deal analysis, coupon tips & specs questionnaire."
        case .writing:
            return "Expands into a content strategist prompt with audience alignment, tone guidelines, Markdown tables & editorial review loop."
        case .analysis:
            return "Expands into a research analyst prompt with data trade-off matrices, grounded citations, evidence tables & analytical verification."
        }
    }
}

public enum LLMProvider: String, CaseIterable, Identifiable {
    case claude = "Claude"
    case gemini = "Gemini"
    case chatgpt = "ChatGPT"
    case grok = "Grok"
    case perplexity = "Perplexity"
    
    public var id: String { self.rawValue }
    
    public var brandColorHex: String {
        switch self {
        case .claude: return "#D97757"     // Warm Terracotta / Anthropic
        case .gemini: return "#4285F4"     // Google Blue
        case .chatgpt: return "#10A37F"    // OpenAI Teal Green
        case .grok: return "#262626"       // xAI Charcoal
        case .perplexity: return "#22B8CF" // Cyan
        }
    }
    
    public var iconName: String {
        switch self {
        case .claude: return "brain.head.profile"
        case .gemini: return "sparkles"
        case .chatgpt: return "bubble.left.and.bubble.right.fill"
        case .grok: return "bolt.horizontal.fill"
        case .perplexity: return "magnifyingglass"
        }
    }
    
    public func targetURL(for promptText: String) -> URL? {
        let trimmed = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        let queryAllowed = CharacterSet.urlQueryAllowed
        let encodedQuery = trimmed.addingPercentEncoding(withAllowedCharacters: queryAllowed) ?? ""
        
        var urlString: String
        switch self {
        case .claude:
            urlString = "https://claude.ai/new"
        case .gemini:
            urlString = "https://gemini.google.com/app"
        case .chatgpt:
            if !encodedQuery.isEmpty && encodedQuery.count < 1500 {
                urlString = "https://chatgpt.com/?q=\(encodedQuery)"
            } else {
                urlString = "https://chatgpt.com/"
            }
        case .grok:
            urlString = "https://grok.com/"
        case .perplexity:
            if !encodedQuery.isEmpty && encodedQuery.count < 1500 {
                urlString = "https://www.perplexity.ai/search?q=\(encodedQuery)"
            } else {
                urlString = "https://www.perplexity.ai/"
            }
        }
        return URL(string: urlString)
    }
}

public struct PromptEngine {
    
    public static func expand(text: String, mode: PromptMode = .comprehensive) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        // If the user has a custom template stored in preferences, apply it.
        // The {input} token is replaced with the user's raw text.
        let customTemplate = AppPreferences.shared.template(for: mode)
        if !customTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customTemplate.replacingOccurrences(of: "{input}", with: trimmed)
        }

        // Fall back to built-in hardcoded prompt builders
        switch mode {
        case .comprehensive:
            return buildComprehensivePrompt(from: trimmed)
        case .shopping:
            return buildShoppingPrompt(from: trimmed)
        case .writing:
            return buildWritingPrompt(from: trimmed)
        case .analysis:
            return buildAnalysisPrompt(from: trimmed)
        }
    }
    
    // MARK: - Detailed Comprehensive Prompt
    private static func buildComprehensivePrompt(from input: String) -> String {
        let topic = extractTopic(from: input)
        let domain = detectDomain(from: input)
        
        return """
        # Goal & Persona
        You are a world-class expert and advisor in \(domain). Your task is to provide a comprehensive, rigorous, and highly actionable solution for the request detailed below.

        # User Objective
        \(input)

        # Context & Requirements
        1. **Domain Context**: Focus specifically on \(topic). Ensure all advice adheres to industry standard best practices.
        2. **Grounded Citations**: Ground all claims, statistics, empirical figures, historical facts, and technical references with clear inline citations or source references wherever possible.
        3. **Visual Presentation (Tables & Charts)**: Present key facts, figures, metrics, statistics, and comparative data using structured Markdown tables, ASCII charts, or comparison grids wherever applicable for easy visual parsing.
        4. **Handling Ambiguity (Questionnaire)**: If the prompt contains ambiguities, missing parameters, or multiple potential execution paths, start your response with a concise **Multiple-Choice Questionnaire** (with options A, B, C) so the user can clarify context for the best possible outcome.
        5. **Depth & Edge Cases**: Proactively identify potential pitfalls, trade-offs, or edge cases, along with actionable mitigation strategies.

        # Self-Correction & Quality Review Loop
        - **Internal Evaluation**: Before rendering your final response, evaluate your initial draft against accuracy, citation grounding, completeness, clarity, data visualization (tables/charts), and structural depth.
        - **Refinement Loop**: If any gaps, ungrounded claims, unformatted data, or lack of depth are detected, perform an internal refinement loop to elevate the response quality to top-tier benchmark standards. Continue refining until excellence is achieved.

        # Step-by-Step Execution Guidelines
        - **Phase 1: Clarification & Overview**: Address ambiguities via a multiple-choice questionnaire if needed, followed by a high-level summary with grounded context.
        - **Phase 2: Structured Solution**: Provide step-by-step resolution, code, or copy with inline citations. Use tables for facts/data visualization and clear markdown formatting throughout.
        - **Phase 3: Validation & Next Steps**: Outline verification steps and practical recommendations.

        # Output Format & Structure
        - Ground all facts and figures with explicit citations.
        - Present all quantitative findings, figures, and comparisons in Markdown tables or visual charts.
        - Include clarifying multiple-choice options if requirements are underspecified.
        - Maintain a crisp, professional, and authoritative tone without unnecessary fluff.
        """
    }
    
    // MARK: - Shopping & Lowest Price Deal Finder Prompt
    private static func buildShoppingPrompt(from input: String) -> String {
        return """
        # System Role: Expert Price Comparison Specialist & Bargain Finder
        You are an elite price comparison specialist and deal researcher. Your task is to find the absolute lowest price, best retailer deals, active coupons, and top value for the product described below.

        # Target Product / Shopping Request
        \(input)

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
        """
    }
    
    // MARK: - Writing & Content Prompt
    private static func buildWritingPrompt(from input: String) -> String {
        return """
        # System Role: Senior Content Strategist & Copywriter
        You are an elite communicator, editor, and content strategist skilled at crafting engaging, persuasive, and crystal-clear text tailored to target audiences.

        # Task Objective
        \(input)

        # Content Guidelines
        1. **Tone & Style**: Professional, engaging, and structured. Adapt tone appropriately to the audience.
        2. **Grounded Citations**: Cite authoritative sources, research studies, or statistics used in the text wherever applicable.
        3. **Visual Tables & Statistics**: Present data points, key facts, audience metrics, and comparative figures using Markdown tables or visual summary grids.
        4. **Ambiguity Questionnaire**: If target audience, tone, length, or goals are underspecified, start with a 2-3 question **Multiple-Choice Questionnaire** to align on tone and intent.
        5. **Structure & Impact**: Use active voice, compelling headers, crisp bullet points, and key takeaway summaries.

        # Self-Correction & Quality Review Loop
        - **Editorial Critique**: Critically evaluate your draft for narrative flow, source grounding, grammatical polish, and visual presentation before displaying it.
        - **Refinement Loop**: Iterate internally until the draft meets publication-level quality.
        """
    }
    
    // MARK: - Analysis & Research Prompt
    private static func buildAnalysisPrompt(from input: String) -> String {
        return """
        # System Role: Lead Data & Research Analyst
        You are an expert research analyst skilled at decomposing complex topics into structured insights, trade-off matrices, and quantitative/qualitative evaluations.

        # Task Objective
        \(input)

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
    }
    
    // MARK: - Helpers
    private static func extractTopic(from text: String) -> String {
        let firstSentence = text.components(separatedBy: CharacterSet(charactersIn: ".!?\n")).first ?? text
        return firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func detectDomain(from text: String) -> String {
        let lower = text.lowercased()
        let shoppingKeywords = ["price", "buy", "deal", "discount", "cost", "cheap", "store", "product", "amazon", "walmart", "sale", "order"]
        let writingKeywords = ["email", "draft", "article", "essay", "letter", "copy", "blog", "write", "rewrite", "post"]
        let analysisKeywords = ["analyze", "compare", "research", "pros", "cons", "strategy", "market", "evaluation", "metrics"]
        
        for kw in shoppingKeywords where lower.contains(kw) {
            return "Retail Price Comparison & E-Commerce"
        }
        for kw in writingKeywords where lower.contains(kw) {
            return "Professional Writing & Communication"
        }
        for kw in analysisKeywords where lower.contains(kw) {
            return "Strategic Analysis & Research"
        }
        return "General Knowledge & Everyday Assistance"
    }
}

// Color Hex Extension for SwiftUI
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
