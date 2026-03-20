//
//  GenratedCodeQuickActionView.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

struct GenratedCodeQuickActionView: View {
    let errorMessage: String?
    let isThereError: Bool
    let generatedOutput: String
    let selectedLang: OutputLanguage
    let onDismiss: (() -> Void)?

    private var highlightedOutput: AttributedString {
        SyntaxHighlighter.highlight(generatedOutput, language: selectedLang)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(selectedLang == .swift ? "Swift" : "Kotlin")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if !generatedOutput.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(generatedOutput, forType: .string)
                        onDismiss?()
                    } label: {
                        Label("Copy & Close", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 4)

            ScrollView {
                Group {
                    if generatedOutput.isEmpty {
                        Text(isThereError ? errorMessage!: "Paste JSON on the left...")
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(isThereError ? .red: .secondary)
                    } else {
                        Text(highlightedOutput)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .textSelection(.enabled)
            .background(Color(nsColor: .textBackgroundColor).opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
        }
    }
}
