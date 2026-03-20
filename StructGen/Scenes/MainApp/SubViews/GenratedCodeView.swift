//
//  GenratedCodeView.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

struct GenratedCodeView: View {
    let errorMessage: String?
    let isThereError: Bool
    let generatedOutput: String
    @Bindable var options: GeneratorOptions

    private var highlightedOutput: AttributedString {
        SyntaxHighlighter.highlight(generatedOutput, language: options.language)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if #available(macOS 26, *) {
                GlassEffectContainer {
                    OptionsView(options: options)
                }
                .glassEffect(.regular.interactive())
            } else {
                OptionsView(options: options)
            }

            ScrollView {
                Group {
                    if generatedOutput.isEmpty {
                        Text(isThereError ? errorMessage!: "Generated code will appear here...")
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(alignment: .topTrailing) {
                if !generatedOutput.isEmpty {
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(generatedOutput, forType: .string)
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }
}

// MARK: - SubViews
private struct OptionsView: View {
    @Bindable var options: GeneratorOptions
    var body: some View {
        HStack {
            Toggle(options.serializationLabel, isOn: $options.addCodable)
                .toggleStyle(.checkbox)

            Toggle("Optionals", isOn: $options.makeOptional)
                .toggleStyle(.checkbox)

            Toggle(options.codingKeysLabel, isOn: $options.generateCodingKeys)
                .toggleStyle(.checkbox)

            Toggle("Nested", isOn: $options.nestStructs)
                .toggleStyle(.checkbox)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
