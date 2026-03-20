//
//  JsonFiledView.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

struct JsonFiledView: View {
    @Binding var jsonInput: String
    let cornerRaduis: CGFloat
    let action: (() -> Void)?

    init(
        jsonInput: Binding<String>,
        cornerRaduis: CGFloat = 8,
        action: (() -> Void)?
    ) {
        _jsonInput = jsonInput
        self.cornerRaduis = cornerRaduis
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JSON")
                .font(.headline)

            JSONTextEditor(text: $jsonInput)
                .clipShape(RoundedRectangle(cornerRadius: cornerRaduis))
                .background(
                    Color(nsColor: .textBackgroundColor),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(alignment: .bottomTrailing) {
                    if let action {
                        Button("Convert") {
                            action()
                        }
                        .glassButtonStyleIfAvailable(prominent: true)
                        .controlSize(.large)
                        .padding()
                    }
                }

        }
    }
}
