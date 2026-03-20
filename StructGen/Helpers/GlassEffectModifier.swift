//
//  GlassEffectModifier.swift
//  StructGen
//
//  Created by Omar Elsayed on 20/03/2026.
//

import SwiftUI

// MARK: - Glass Effect

struct GlassEffectModifier<S: Shape>: ViewModifier {
    var shape: S

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content
                .glassEffect(.regular.interactive(), in: shape)
        } else {
            content
        }
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyleModifier: ViewModifier {
    var prominent: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else {
            if prominent {
                content.buttonStyle(.borderedProminent)
            } else {
                content.buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func glassEffectIfAvailable<S: Shape>(in shape: S = Capsule()) -> some View {
        modifier(GlassEffectModifier(shape: shape))
    }

    func glassButtonStyleIfAvailable(prominent: Bool = false) -> some View {
        modifier(GlassButtonStyleModifier(prominent: prominent))
    }
}
