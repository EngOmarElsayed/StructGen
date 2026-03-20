//
//  OptionsQuickActionView.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

struct OptionsQuickActionView: View {
    @Bindable var options: GeneratorOptions

    var body: some View {
        HStack(spacing: 16) {
            Toggle(options.serializationLabel, isOn: $options.addCodable)
                .toggleStyle(.checkbox)
                .controlSize(.small)

            Toggle("Optionals", isOn: $options.makeOptional)
                .toggleStyle(.checkbox)
                .controlSize(.small)

            Toggle(options.codingKeysLabel, isOn: $options.generateCodingKeys)
                .toggleStyle(.checkbox)
                .controlSize(.small)

            Toggle("Nested", isOn: $options.nestStructs)
                .toggleStyle(.checkbox)
                .controlSize(.small)
        }
    }
}
