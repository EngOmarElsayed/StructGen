//
//  SyntaxHighlighter.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

enum SyntaxHighlighter {

    // MARK: - Colors (Adaptive: Xcode Light + Dark)

    private enum TokenColor {
        static let keyword  = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.988, green: 0.373, blue: 0.639, alpha: 1) // dark: #FC5FA3
                : NSColor(red: 0.608, green: 0.137, blue: 0.576, alpha: 1) // light: #9B2393
        })
        static let type = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.816, green: 0.749, blue: 0.412, alpha: 1) // dark: #D0BF69
                : NSColor(red: 0.110, green: 0.337, blue: 0.651, alpha: 1) // light: #1C56A6
        })
        static let proto = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.255, green: 0.753, blue: 0.710, alpha: 1) // dark: #41C0B5
                : NSColor(red: 0.024, green: 0.388, blue: 0.451, alpha: 1) // light: #063B73
        })
        static let string = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.988, green: 0.416, blue: 0.365, alpha: 1) // dark: #FC6A5D
                : NSColor(red: 0.769, green: 0.102, blue: 0.086, alpha: 1) // light: #C41A16
        })
        static let typeName = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.471, green: 0.761, blue: 0.702, alpha: 1) // dark: #78C2B3
                : NSColor(red: 0.110, green: 0.337, blue: 0.651, alpha: 1) // light: #1C56A6
        })
        static let plain = Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.831, green: 0.831, blue: 0.831, alpha: 1) // dark: #D4D4D4
                : NSColor(red: 0.149, green: 0.149, blue: 0.149, alpha: 1) // light: #262626
        })
    }

    // MARK: - Token Rules

    private struct TokenRule {
        let pattern: String
        let color: Color
        /// When non-nil, apply color only to this capture group index instead of the full match.
        let captureGroup: Int?

        init(pattern: String, color: Color, captureGroup: Int? = nil) {
            self.pattern = pattern
            self.color = color
            self.captureGroup = captureGroup
        }
    }

    // MARK: - Swift Rules

    private static let swiftRules: [TokenRule] = [
        TokenRule(pattern: #"\b(\d+(\.\d+)?)\b"#, color: TokenColor.type),
        TokenRule(pattern: #"\b(String|Int|Double|Bool|Date|URL|Any|Float)\b"#, color: TokenColor.type),
        TokenRule(pattern: #"\b(Codable|CodingKey|Decodable|Encodable)\b"#, color: TokenColor.proto),
        TokenRule(pattern: #"\b(struct|enum|case|let|var)\b"#, color: TokenColor.keyword),
        TokenRule(pattern: #"\bstruct\s+(\w+)"#, color: TokenColor.typeName, captureGroup: 1),
        TokenRule(pattern: #""[^"]*""#, color: TokenColor.string),
    ]

    // MARK: - Kotlin Rules

    private static let kotlinRules: [TokenRule] = [
        TokenRule(pattern: #"\b(\d+(\.\d+)?)\b"#, color: TokenColor.type),
        TokenRule(pattern: #"\b(String|Int|Double|Boolean|Long|Float|List|Any)\b"#, color: TokenColor.type),
        TokenRule(pattern: #"\b(Serializable)\b"#, color: TokenColor.proto),
        TokenRule(pattern: #"\b(data|class|val|var|fun|object|companion|override)\b"#, color: TokenColor.keyword),
        TokenRule(pattern: #"@\w+"#, color: TokenColor.type),
        TokenRule(pattern: #"\bclass\s+(\w+)"#, color: TokenColor.typeName, captureGroup: 1),
        TokenRule(pattern: #""[^"]*""#, color: TokenColor.string),
    ]

    // MARK: - Public API

    static func highlight(_ code: String, language: OutputLanguage) -> AttributedString {
        var result = AttributedString(code)
        result.foregroundColor = TokenColor.plain
        result.font = .system(.body, design: .monospaced)

        let rules = language == .swift ? swiftRules : kotlinRules

        for rule in rules {
            guard let regex = try? NSRegularExpression(pattern: rule.pattern) else { continue }
            let nsRange = NSRange(code.startIndex..., in: code)
            let matches = regex.matches(in: code, range: nsRange)

            for match in matches {
                let rangeIndex = rule.captureGroup ?? 0
                guard rangeIndex < match.numberOfRanges else { continue }
                let matchNSRange = match.range(at: rangeIndex)
                guard matchNSRange.location != NSNotFound,
                      let swiftRange = Range(matchNSRange, in: code) else { continue }

                let startOffset = code.distance(from: code.startIndex, to: swiftRange.lowerBound)
                let endOffset = code.distance(from: code.startIndex, to: swiftRange.upperBound)

                let attrStart = result.index(result.startIndex, offsetByCharacters: startOffset)
                let attrEnd = result.index(result.startIndex, offsetByCharacters: endOffset)

                result[attrStart..<attrEnd].foregroundColor = rule.color
            }
        }

        return result
    }
}
