//
//  GlassCardView.swift
//  ExpenseTracker
//
//  The reusable "liquid glass" container used across the app.
//
//  Design note on iOS 26 Liquid Glass: rather than calling iOS-26-only symbols
//  (which would not compile against the iOS 17/18 SDK and would crash on older
//  devices), we lean on system materials — `.ultraThinMaterial` /
//  `.regularMaterial`. These render as translucent glass on iOS 17+ and are
//  automatically upgraded to the richer Liquid Glass treatment by the system
//  on iOS 26, so the same code looks great everywhere and degrades gracefully.
//

import SwiftUI

/// A rounded translucent card. Wrap any content to give it the app's glass look.
struct GlassCardView<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var material: Material = .ultraThinMaterial
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// View modifier form, for cases where wrapping in a container is awkward.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var material: Material = .ultraThinMaterial

    func body(content: Content) -> some View {
        content
            .background(material, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

extension View {
    /// Applies the app's glass background to any view.
    func glassCard(cornerRadius: CGFloat = 20, material: Material = .ultraThinMaterial) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius, material: material))
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        GlassCardView {
            VStack(alignment: .leading) {
                Text("Glass card").font(.headline)
                Text("ultraThinMaterial").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
