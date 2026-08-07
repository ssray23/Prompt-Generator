import SwiftUI
import AppKit

public class PromptSessionManager: ObservableObject {
    public static let shared = PromptSessionManager()
    
    @Published public var inputs: [PromptMode: String] = [:]
    
    private init() {
        for mode in PromptMode.allCases {
            inputs[mode] = ""
        }
    }
    
    // MARK: - CSV Export / Import
    
    public func exportToCSV() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.canCreateDirectories = true
        
        let formatter = DateFormatter()
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        formatter.dateFormat = "EEE d MMM h-mm a"
        let dateString = formatter.string(from: Date())
        savePanel.nameFieldStringValue = "PromptInputs_\(dateString).csv"
        
        NSApp.activate(ignoringOtherApps: true)
        if let window = QuickEntryWindowController.shared.window, window.isVisible {
            savePanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = savePanel.url {
                    self.saveCSV(to: url)
                }
            }
        } else {
            if savePanel.runModal() == .OK, let url = savePanel.url {
                self.saveCSV(to: url)
            }
        }
    }
    
    public func importFromCSV() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.commaSeparatedText]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        
        NSApp.activate(ignoringOtherApps: true)
        if let window = QuickEntryWindowController.shared.window, window.isVisible {
            openPanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = openPanel.url {
                    self.loadCSV(from: url)
                }
            }
        } else {
            if openPanel.runModal() == .OK, let url = openPanel.url {
                self.loadCSV(from: url)
            }
        }
    }
    
    private func saveCSV(to url: URL) {
        var csvString = "Tab Name,Input Text\n"
        
        for mode in PromptMode.allCases {
            let text = inputs[mode] ?? ""
            let escapedText = escapeForCSV(text)
            csvString += "\(mode.rawValue),\(escapedText)\n"
        }
        
        do {
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            DispatchQueue.main.async {
                HUDWindowController.shared.show(state: .success("Successfully exported CSV"))
            }
        } catch {
            print("Error saving CSV: \(error)")
            DispatchQueue.main.async {
                HUDWindowController.shared.show(state: .error("Failed to export CSV"))
            }
        }
    }
    
    private func loadCSV(from url: URL) {
        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            let lines = parseCSV(content)
            
            var newInputs: [PromptMode: String] = [:]
            
            // Skip the header row (Tab Name, Input Text)
            for i in 1..<lines.count {
                let row = lines[i]
                if row.count >= 2 {
                    let tabName = row[0]
                    let inputText = row[1]
                    
                    if let mode = PromptMode.allCases.first(where: { $0.rawValue == tabName }) {
                        newInputs[mode] = inputText
                    }
                }
            }
            
            DispatchQueue.main.async {
                for (mode, text) in newInputs {
                    self.inputs[mode] = text
                }
                HUDWindowController.shared.show(state: .success("Successfully imported CSV"))
            }
        } catch {
            print("Error loading CSV: \(error)")
            DispatchQueue.main.async {
                HUDWindowController.shared.show(state: .error("Failed to import CSV"))
            }
        }
    }
    
    private func escapeForCSV(_ string: String) -> String {
        var escaped = string
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            escaped = escaped.replacingOccurrences(of: "\"", with: "\"\"")
            escaped = "\"\(escaped)\""
        }
        return escaped
    }
    
    private func parseCSV(_ content: String) -> [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        
        var insideQuotes = false
        
        let characters = Array(content)
        var i = 0
        
        while i < characters.count {
            let char = characters[i]
            
            if char == "\"" {
                if insideQuotes && i + 1 < characters.count && characters[i + 1] == "\"" {
                    currentField.append("\"")
                    i += 1
                } else {
                    insideQuotes.toggle()
                }
            } else if char == "," && !insideQuotes {
                currentRow.append(currentField)
                currentField = ""
            } else if (char == "\n" || char == "\r\n") && !insideQuotes {
                currentRow.append(currentField)
                result.append(currentRow)
                currentRow = []
                currentField = ""
                // Skip \n if it's \r\n
                if char == "\r" && i + 1 < characters.count && characters[i + 1] == "\n" {
                    i += 1
                }
            } else {
                currentField.append(char)
            }
            
            i += 1
        }
        
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            result.append(currentRow)
        }
        
        return result
    }
}
