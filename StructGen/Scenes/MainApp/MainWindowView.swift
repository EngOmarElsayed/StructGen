//
//  MainWindowView.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

struct MainWindowView: View {
    @State private var jsonInput: String = ""
    @State private var generatedOutput: String = ""
    @State private var errorMessage: String?
    @State private var options = GeneratorOptions()
    @State private var isThereError = false

    var body: some View {
        HSplitView {
            JsonFiledView(
                jsonInput: $jsonInput,
                action: convert
            )
            .padding()
            .frame(minWidth: 250)
            
            GenratedCodeView(
                errorMessage: errorMessage,
                isThereError: isThereError,
                generatedOutput: generatedOutput,
                options: options
            )
            .padding()
            .frame(minWidth: 250)
        }
        .toolbar {
            ToolbarItemGroup {
                Picker("Language", selection: $options.language) {
                    ForEach(OutputLanguage.allCases) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }
        }
        .onChange(of: options.language) { convertIfNeeded() }
        .onChange(of: options.addCodable) { convertIfNeeded() }
        .onChange(of: options.makeOptional) { convertIfNeeded() }
        .onChange(of: options.generateCodingKeys) { convertIfNeeded() }
        .onChange(of: options.nestStructs) { convertIfNeeded() }
        .frame(minWidth: 800, minHeight: 500)
        .background(VisualEffectBackground())
    }

    // MARK: - Actions
    private func convert() {
        errorMessage = nil
        generatedOutput = ""

        let trimmed = jsonInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Paste some JSON to get started."
            isThereError = true
            return
        }

        let result = StructGenerator.generate(from: trimmed, options: options)
        switch result {
        case .success(let code):
            generatedOutput = code
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    private func convertIfNeeded() {
        let trimmed = jsonInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        convert()
    }
}

//// Pretty-print the JSON input
//if let data = trimmed.data(using: .utf8),
//   let jsonObject = try? JSONSerialization.jsonObject(with: data),
//   let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
//   let prettyString = String(data: prettyData, encoding: .utf8) {
//    jsonInput = prettyString
//}
