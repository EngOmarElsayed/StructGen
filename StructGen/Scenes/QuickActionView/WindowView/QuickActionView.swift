import SwiftUI

struct QuickActionView: View {
    @State private var jsonInput: String = ""
    @State private var generatedOutput: String = ""
    @State private var isThereError: Bool = false
    @State private var errorMessage: String?
    @State private var options = GeneratorOptions()
    var onDismiss: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            quickActionHeaderView()
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

            Divider()

            HSplitView {
                JsonFiledView(
                    jsonInput: $jsonInput,
                    cornerRaduis: 6,
                    action: nil
                )
                .padding(10)
                .frame(minWidth: 250)

                GenratedCodeQuickActionView(
                    errorMessage: errorMessage,
                    isThereError: isThereError,
                    generatedOutput: generatedOutput,
                    selectedLang: options.language,
                    onDismiss: onDismiss
                )
                .padding(10)
                .frame(minWidth: 250)
            }
            .padding(.horizontal, 8)

            Divider()

            OptionsQuickActionView(options: options)
                .padding(.horizontal, 16)
                .padding(.vertical)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 700, height: 450)
        .background(VisualEffectBackground())
        .onChange(of: jsonInput) { convert() }
        .onChange(of: options.language) { convert() }
        .onChange(of: options.addCodable) { convert() }
        .onChange(of: options.makeOptional) { convert() }
        .onChange(of: options.generateCodingKeys) { convert() }
        .onChange(of: options.nestStructs) { convert() }
    }

    // MARK: - SubViews
    private func quickActionHeaderView() -> some View {
        HStack {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.secondary)
            Text("Quick Convert")
                .font(.headline)

            Spacer()

            Picker("", selection: $options.language) {
                ForEach(OutputLanguage.allCases) { lang in
                    Text(lang.rawValue).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 130)

            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
    }

    // MARK: - Actions
    private func convert() {
        errorMessage = nil
        generatedOutput = ""

        let trimmed = jsonInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let result = StructGenerator.generate(from: trimmed, options: options)
        switch result {
        case .success(let code):
            generatedOutput = code
        case .failure(let error):
            errorMessage = error.localizedDescription
            isThereError = true
        }
    }
}
