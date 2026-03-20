import Foundation
import Observation

@Observable
final class GeneratorOptions {
    var language: OutputLanguage = .swift
    var addCodable: Bool = true
    var makeOptional: Bool = false
    var generateCodingKeys: Bool = false
    var nestStructs: Bool = true

    var serializationLabel: String {
        switch language {
        case .swift:  "Codable"
        case .kotlin: "Serializable"
        }
    }

    var codingKeysLabel: String {
        switch language {
        case .swift:  "CodingKeys"
        case .kotlin: "@SerializedName"
        }
    }
}
