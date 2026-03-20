import Foundation

enum OutputLanguage: String, CaseIterable, Identifiable {
    case swift = "Swift"
    case kotlin = "Kotlin"

    var id: String { rawValue }
}
