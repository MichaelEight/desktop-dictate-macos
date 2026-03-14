import Foundation
import os

enum TextPostProcessor {
    // MARK: - Junk Token Filtering

    private static let junkPatterns: [String] = [
        "[BLANK_AUDIO]", "(BLANK_AUDIO)", "[silence]", "(silence)",
        "[Music]", "(Music)", "[music]", "(music)",
        "(gentle music)", "(sighs)", "(laughs)", "(applause)",
        "(coughing)", "(breathing)", "(clicking)", "(typing)",
        "[inaudible]", "(inaudible)",
    ]

    /// Remove hallucinated noise tokens and bracketed/parenthesized descriptions.
    static func filterJunkTokens(_ text: String) -> String {
        var result = text
        for pattern in junkPatterns {
            result = result.replacingOccurrences(of: pattern, with: "")
        }
        // Remove any remaining (parenthetical) or [bracketed] noise descriptions
        result = result.replacingOccurrences(
            of: "\\([^)]*\\)|\\[[^\\]]*\\]",
            with: "",
            options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Default LLM Prompt

    static let defaultSystemPrompt = """
        You are a dictation post-processor. Clean up the following transcribed speech: \
        fix punctuation, capitalization, and obvious transcription errors. \
        Preserve the speaker's intended meaning exactly. Output only the corrected text, nothing else.
        """

    // MARK: - Text Commands

    /// Dictation commands mapped to their text replacements.
    /// Ordered longest-first so "new paragraph" matches before "new".
    static let textCommands: [(phrase: String, replacement: String)] = [
        ("new paragraph", "\n\n"),
        ("new line", "\n"),
        ("full stop", "."),
        ("period", "."),
        ("comma", ","),
        ("question mark", "?"),
        ("exclamation mark", "!"),
        ("exclamation point", "!"),
        ("semicolon", ";"),
        ("open parenthesis", "("),
        ("close parenthesis", ")"),
        ("open paren", "("),
        ("close paren", ")"),
        ("open bracket", "["),
        ("close bracket", "]"),
        ("open brace", "{"),
        ("close brace", "}"),
    ]

    static func applyTextCommands(_ text: String) -> String {
        var result = text
        for cmd in textCommands {
            let escaped = NSRegularExpression.escapedPattern(for: cmd.phrase)
            result = result.replacingOccurrences(
                of: "\\b\(escaped)\\b",
                with: cmd.replacement,
                options: [.regularExpression, .caseInsensitive]
            )
        }
        // Remove trailing space before punctuation that was inserted
        result = result.replacingOccurrences(of: #" \."#, with: ".")
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: #" \?"#, with: "?")
        result = result.replacingOccurrences(of: " !", with: "!")
        result = result.replacingOccurrences(of: " ;", with: ";")
        result = result.replacingOccurrences(of: " \n", with: "\n")
        result = result.replacingOccurrences(of: "\n ", with: "\n")
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - LLM Post-Processing

    static func llmProcess(
        text: String,
        endpoint: String,
        apiKey: String,
        model: String,
        systemPrompt: String
    ) async throws -> String {
        guard let url = URL(string: endpoint) else {
            Logger.transcription.error("Invalid LLM endpoint URL: \(endpoint)")
            return text
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text],
            ],
            "temperature": 0.3,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            Logger.transcription.error("LLM API returned status \(code)")
            return text
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String
        else {
            Logger.transcription.error("Failed to parse LLM API response")
            return text
        }

        let cleaned = content.trimmingCharacters(in: .whitespacesAndNewlines)
        Logger.transcription.info("LLM post-processed: '\(text.prefix(40))' → '\(cleaned.prefix(40))'")
        return cleaned.isEmpty ? text : cleaned
    }
}
