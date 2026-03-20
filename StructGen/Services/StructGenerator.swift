//
//  StructGenerator.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import Foundation

enum StructGenerator {

    // MARK: - Public

    static func generate(from jsonString: String, options: GeneratorOptions) -> Result<String, GenerationError> {
        guard let data = jsonString.data(using: .utf8) else {
            return .failure(.invalidJSON("Input is not valid UTF-8 text."))
        }

        let parsed: Any
        do {
            parsed = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
        } catch {
            return .failure(.invalidJSON("Invalid JSON: \(error.localizedDescription)"))
        }

        guard let rootObject = parsed as? [String: Any] else {
            return .failure(.invalidJSON("Root must be a JSON object (not array or primitive)."))
        }

        var collector = StructCollector(options: options)
        collector.parse(name: "Root", object: rootObject, isRoot: true)

        let output = collector.render()
        return .success(output)
    }

    // MARK: - Error

    enum GenerationError: LocalizedError {
        case invalidJSON(String)

        var errorDescription: String? {
            switch self {
            case .invalidJSON(let message): return message
            }
        }
    }
}

// MARK: - StructCollector
fileprivate struct StructCollector {
    let options: GeneratorOptions
    var flatStructs: [(depth: Int, definition: StructDefinition)] = []
    var rootDefinition: StructDefinition?
    var currentDepth: Int = 0

    struct StructDefinition {
        let name: String
        var properties: [(key: String, swiftName: String, swiftType: String)]
        var nestedStructs: [StructDefinition]
        var codingKeys: [(swiftName: String, jsonKey: String)]
    }

    // MARK: - Parsing

    mutating func parse(name: String, object: [String: Any], isRoot: Bool) {
        let structName = sanitizeTypeName(name)
        var definition = StructDefinition(
            name: structName,
            properties: [],
            nestedStructs: [],
            codingKeys: []
        )

        let sortedKeys = object.keys.sorted()

        for key in sortedKeys {
            let value = object[key]!
            let swiftName = options.generateCodingKeys ? camelCase(key) : key
            let swiftType = inferType(key: key, value: value, parent: &definition)

            let finalType = options.makeOptional ? "\(swiftType)?" : swiftType
            definition.properties.append((key: key, swiftName: swiftName, swiftType: finalType))

            if options.generateCodingKeys && swiftName != key {
                definition.codingKeys.append((swiftName: swiftName, jsonKey: key))
            }
        }

        if isRoot {
            rootDefinition = definition
        } else if !options.nestStructs {
            flatStructs.append((depth: currentDepth, definition: definition))
        }
    }

    // MARK: - Type Inference

    private mutating func inferType(key: String, value: Any, parent: inout StructDefinition) -> String {
        if value is NSNull {
            return "String" // fallback for null
        }
        if let string = value as? String {
            return inferStringType(string)
        }
        if let number = value as? NSNumber {
            // CFBoolean is a distinct type from NSNumber for integers.
            // Without this check, 0 and 1 are misidentified as Bool.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return "Bool"
            }
            if value is Int {
                return "Int"
            }
            return "Double"
        }
        if let array = value as? [Any] {
            return inferArrayType(key: key, array: array, parent: &parent)
        }
        if let nested = value as? [String: Any] {
            return inferObjectType(key: key, object: nested, parent: &parent)
        }
        return "Any"
    }

    private func inferStringType(_ value: String) -> String {
        // Simple heuristic checks
        if value.contains("://") || value.hasPrefix("http") {
            return "String" // could be URL but keep it simple
        }
        return "String"
    }

    private mutating func inferArrayType(key: String, array: [Any], parent: inout StructDefinition) -> String {
        guard let first = array.first else {
            return "[Any]"
        }

        if first is String { return "[String]" }
        if first is Bool { return "[Bool]" }
        if first is Int { return "[Int]" }
        if first is Double { return "[Double]" }

        if let nested = first as? [String: Any] {
            let singularKey = singularize(key)
            let childType = inferObjectType(key: singularKey, object: nested, parent: &parent)
            return "[\(childType)]"
        }

        return "[Any]"
    }

    private mutating func inferObjectType(key: String, object: [String: Any], parent: inout StructDefinition) -> String {
        let typeName = sanitizeTypeName(key)

        if options.nestStructs {
            // Build a nested struct definition inline
            var nested = StructDefinition(
                name: typeName,
                properties: [],
                nestedStructs: [],
                codingKeys: []
            )

            let sortedKeys = object.keys.sorted()
            for childKey in sortedKeys {
                let childValue = object[childKey]!
                let swiftName = options.generateCodingKeys ? camelCase(childKey) : childKey
                let swiftType = inferType(key: childKey, value: childValue, parent: &nested)
                let finalType = options.makeOptional ? "\(swiftType)?" : swiftType
                nested.properties.append((key: childKey, swiftName: swiftName, swiftType: finalType))

                if options.generateCodingKeys && swiftName != childKey {
                    nested.codingKeys.append((swiftName: swiftName, jsonKey: childKey))
                }
            }

            parent.nestedStructs.append(nested)
        } else {
            currentDepth += 1
            parse(name: key, object: object, isRoot: false)
            currentDepth -= 1
        }

        return typeName
    }

    // MARK: - Rendering

    func render() -> String {
        guard let root = rootDefinition else { return "" }

        // Sort flat structs by depth (shallowest first) so parent structs
        // appear before child structs they reference.
        let sortedFlat = flatStructs.sorted { $0.depth < $1.depth }.map(\.definition)

        var lines: [String] = []

        switch options.language {
        case .swift:
            renderSwift(root, indent: 0, into: &lines)
            if !options.nestStructs {
                for flat in sortedFlat {
                    lines.append("")
                    renderSwift(flat, indent: 0, into: &lines)
                }
            }
        case .kotlin:
            renderKotlin(root, indent: 0, into: &lines)
            if !options.nestStructs {
                for flat in sortedFlat {
                    lines.append("")
                    renderKotlin(flat, indent: 0, into: &lines)
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Swift Rendering

    private func renderSwift(_ def: StructDefinition, indent: Int, into lines: inout [String]) {
        let pad = String(repeating: "    ", count: indent)
        let conformance = options.addCodable ? ": Codable" : ""

        lines.append("\(pad)struct \(def.name)\(conformance) {")

        for prop in def.properties {
            lines.append("\(pad)    let \(prop.swiftName): \(prop.swiftType)")
        }

        if !def.codingKeys.isEmpty {
            lines.append("")
            lines.append("\(pad)    enum CodingKeys: String, CodingKey {")
            for ck in def.codingKeys {
                lines.append("\(pad)        case \(ck.swiftName) = \"\(ck.jsonKey)\"")
            }
            // Also add keys that don't need mapping
            for prop in def.properties where !def.codingKeys.contains(where: { $0.swiftName == prop.swiftName }) {
                lines.append("\(pad)        case \(prop.swiftName)")
            }
            lines.append("\(pad)    }")
        }

        for nested in def.nestedStructs {
            lines.append("")
            renderSwift(nested, indent: indent + 1, into: &lines)
        }

        lines.append("\(pad)}")
    }

    // MARK: - Kotlin Rendering

    private func kotlinType(_ swiftType: String) -> String {
        if swiftType.hasSuffix("?") {
            return kotlinType(String(swiftType.dropLast())) + "?"
        }
        if swiftType.hasPrefix("[") && swiftType.hasSuffix("]") {
            let inner = String(swiftType.dropFirst().dropLast())
            return "List<\(kotlinType(inner))>"
        }
        switch swiftType {
        case "Bool": return "Boolean"
        default:     return swiftType
        }
    }

    private func renderKotlin(_ def: StructDefinition, indent: Int, into lines: inout [String]) {
        let pad = String(repeating: "    ", count: indent)
        let hasBody = !def.nestedStructs.isEmpty

        if options.addCodable {
            lines.append("\(pad)@Serializable")
        }

        lines.append("\(pad)data class \(def.name)(")

        for (index, prop) in def.properties.enumerated() {
            let ktType = kotlinType(prop.swiftType)
            let comma = index < def.properties.count - 1 ? "," : ""

            if options.generateCodingKeys && prop.swiftName != prop.key {
                lines.append("\(pad)    @SerializedName(\"\(prop.key)\") val \(prop.swiftName): \(ktType)\(comma)")
            } else {
                lines.append("\(pad)    val \(prop.swiftName): \(ktType)\(comma)")
            }
        }

        if hasBody {
            lines.append("\(pad)) {")
            for nested in def.nestedStructs {
                lines.append("")
                renderKotlin(nested, indent: indent + 1, into: &lines)
            }
            lines.append("\(pad)}")
        } else {
            lines.append("\(pad))")
        }
    }

    // MARK: - Helpers

    private func sanitizeTypeName(_ name: String) -> String {
        let cleaned = name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
        let parts = cleaned.split(separator: " ")
        let capitalized = parts.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        let result = capitalized.joined()
        return result.isEmpty ? "Unknown" : result
    }

    private func camelCase(_ key: String) -> String {
        let parts = key.split(separator: "_")
        guard let first = parts.first else { return key }
        let rest = parts.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst() }
        return String(first) + rest.joined()
    }

    private func singularize(_ word: String) -> String {
        let lowered = word.lowercased()

        // Common irregular plurals
        let irregulars: [String: String] = [
            "people": "person", "children": "child", "men": "man",
            "women": "woman", "mice": "mouse", "geese": "goose",
            "teeth": "tooth", "feet": "foot", "data": "datum",
            "indices": "index", "matrices": "matrix", "vertices": "vertex",
            "analyses": "analysis", "statuses": "status",
        ]
        if let irregular = irregulars[lowered] {
            // Preserve original casing of first char
            if word.first?.isUppercase == true {
                return irregular.prefix(1).uppercased() + irregular.dropFirst()
            }
            return irregular
        }

        // Don't singularize words that already look singular or end in "ss"
        if lowered.hasSuffix("ss") || lowered.hasSuffix("us") {
            return word
        }

        // -ies → -y (e.g., "categories" → "category")
        if lowered.hasSuffix("ies") {
            return String(word.dropLast(3)) + "y"
        }

        // -ses, -xes, -zes, -ches, -shes → drop "es"
        if lowered.hasSuffix("ses") || lowered.hasSuffix("xes") ||
           lowered.hasSuffix("zes") || lowered.hasSuffix("ches") ||
           lowered.hasSuffix("shes") {
            return String(word.dropLast(2))
        }

        // -s → drop "s" (the common case: "orders" → "order")
        if lowered.hasSuffix("s") && !lowered.hasSuffix("ss") {
            return String(word.dropLast())
        }

        return word
    }
}
