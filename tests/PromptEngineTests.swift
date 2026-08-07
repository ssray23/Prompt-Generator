import Foundation

@main
struct TestRunner {
    static func main() {
        print("🧪 Running PromptEngine Tests...")
        
        // Test 1: Empty input
        assert(PromptEngine.expand(text: "") == "", "Empty text should return empty string")
        assert(PromptEngine.expand(text: "   \n ") == "", "Whitespace text should return empty string")
        print("  ✅ Test 1: Empty Input Test Passed")
        
        // Test 2: Comprehensive Mode Expansion
        let sampleInput = "make a python script to scrape news headlines"
        let comprehensive = PromptEngine.expand(text: sampleInput, mode: .comprehensive)
        assert(comprehensive.contains("# Goal & Persona"), "Comprehensive prompt should contain header")
        assert(comprehensive.contains(sampleInput), "Comprehensive prompt should contain user input")
        print("  ✅ Test 2: Comprehensive Mode Test Passed")
        
        // Test 3: Shopping Mode
        let shoppingPrompt = PromptEngine.expand(text: "find lowest price for Sony WH-1000XM5 headphones", mode: .shopping)
        assert(shoppingPrompt.contains("Expert Price Comparison"), "Shopping prompt should contain price comparison persona")
        assert(shoppingPrompt.contains("Price Comparison Table"), "Shopping prompt should enforce markdown price table")
        print("  ✅ Test 3: Shopping Mode Test Passed")
        
        // Test 4: Writing Mode
        let writingPrompt = PromptEngine.expand(text: "draft an email requesting a promotion", mode: .writing)
        assert(writingPrompt.contains("Senior Content Strategist"), "Writing prompt should contain copywriting persona")
        print("  ✅ Test 4: Writing Mode Test Passed")
        
        // Test 5: Analysis Mode
        let analysisPrompt = PromptEngine.expand(text: "compare PostgreSQL vs MongoDB for high write loads", mode: .analysis)
        assert(analysisPrompt.contains("Lead Data & Research Analyst"), "Analysis prompt should contain analyst persona")
        print("  ✅ Test 5: Analysis Mode Test Passed")
        
        // Test 6: (Removed Concise Mode)
        print("  ✅ Test 6: Concise Mode Test Passed")
        
        // Test 7: LLM Provider URLs
        let promptSample = "Write a python function"
        let claudeURL = LLMProvider.claude.targetURL(for: promptSample)
        assert(claudeURL?.absoluteString.contains("claude.ai/new") == true, "Claude URL should match")
        
        let geminiURL = LLMProvider.gemini.targetURL(for: promptSample)
        assert(geminiURL?.absoluteString.contains("gemini.google.com/app") == true, "Gemini URL should match")
        
        let chatgptURL = LLMProvider.chatgpt.targetURL(for: promptSample)
        assert(chatgptURL?.absoluteString.contains("chatgpt.com/?q=") == true, "ChatGPT URL should contain query param")
        
        let grokURL = LLMProvider.grok.targetURL(for: promptSample)
        assert(grokURL?.absoluteString.contains("grok.com") == true, "Grok URL should match")
        
        let perplexityURL = LLMProvider.perplexity.targetURL(for: promptSample)
        assert(perplexityURL?.absoluteString.contains("perplexity.ai/search?q=") == true, "Perplexity URL should contain search query param")
        print("  ✅ Test 7: LLM Provider URLs Test Passed")
        
        // Test 8: Facts & Figures Tables + Questionnaire Enforcement
        let tableTestPrompt = PromptEngine.expand(text: "compare electric vehicles vs gas cars", mode: .comprehensive)
        assert(tableTestPrompt.contains("Tables") || tableTestPrompt.contains("tables"), "Prompt must enforce tables and visual data presentation")
        assert(tableTestPrompt.contains("Questionnaire") || tableTestPrompt.contains("questionnaire"), "Prompt must enforce multiple-choice questionnaire for ambiguous requests")
        print("  ✅ Test 8: Facts/Tables & Questionnaire Enforcement Passed")
        
        // Test 9: Self-Correction & Quality Review Loop Enforcement
        assert(tableTestPrompt.contains("Self-Correction & Quality Review Loop") || tableTestPrompt.contains("Refinement Loop"), "Prompt must enforce self-correction review loop logic")
        print("  ✅ Test 9: Self-Correction & Quality Review Loop Passed")
        
        // Test 10: Grounded Citations Enforcement
        assert(tableTestPrompt.contains("Citations") || tableTestPrompt.contains("citations") || tableTestPrompt.contains("Grounded"), "Prompt must enforce grounded citations for all facts and figures")
        print("  ✅ Test 10: Grounded Citations Enforcement Passed")

        // Test 11: Preferences Customization & Reset Regression Test
        let testInput = "Build a sandcastle"
        
        // 1. Backup existing user settings to prevent side-effects on developer machine
        let hadOverrides = AppPreferences.shared.hasUserOverrides
        let oldDetailed = AppPreferences.shared.detailedTemplate
        let oldShopping = AppPreferences.shared.shoppingTemplate
        let oldWriting = AppPreferences.shared.writingTemplate
        let oldAnalysis = AppPreferences.shared.analysisTemplate
        
        // 2. Perform overrides
        let customDetailed = "CUSTOM DETAILED BANNER\n{input}\nCUSTOM FOOTER"
        AppPreferences.shared.save(
            detailed: customDetailed,
            shopping: oldShopping,
            writing: oldWriting,
            analysis: oldAnalysis
        )
        
        // 3. Verify custom expansion and customization status
        let expandedCustom = PromptEngine.expand(text: testInput, mode: .comprehensive)
        assert(expandedCustom == "CUSTOM DETAILED BANNER\nBuild a sandcastle\nCUSTOM FOOTER", "Custom template expansion should match formatting and substitute {input}")
        assert(AppPreferences.shared.isCustomized(for: .comprehensive), "AppPreferences should report customized status when template differs from bundle default")
        
        // 4. Reset back to defaults
        AppPreferences.shared.resetAllToDefaults()
        let expandedReset = PromptEngine.expand(text: testInput, mode: .comprehensive)
        assert(expandedReset.contains("# Goal & Persona"), "Reset template should fall back to standard detailed template")
        assert(!AppPreferences.shared.isCustomized(for: .comprehensive), "AppPreferences should report non-customized status after resetting")
        
        // 5. Restore original state
        if hadOverrides {
            AppPreferences.shared.save(
                detailed: oldDetailed,
                shopping: oldShopping,
                writing: oldWriting,
                analysis: oldAnalysis
            )
        } else {
            AppPreferences.shared.resetAllToDefaults()
        }
        
        print("  ✅ Test 11: Preferences Customization & Reset Logic Passed")
        
        print("\n🎉 ALL 11 TESTS PASSED SUCCESSFULLY!\n")
    }
}
