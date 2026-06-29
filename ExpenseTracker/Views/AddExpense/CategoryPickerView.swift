//
//  CategoryPickerView.swift
//  ExpenseTracker
//
//  A horizontally scrolling row of category chips. The selected chip fills
//  with the category color; the rest stay glassy.
//

import SwiftUI

struct CategoryPickerView: View {
    @Binding var selected: ExpenseCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExpenseCategory.allCases) { category in
                    chip(for: category)
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    private func chip(for category: ExpenseCategory) -> some View {
        let isSelected = category == selected
        return Button {
            withAnimation(.spring(duration: 0.3)) { selected = category }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.footnote.weight(.semibold))
                Text(category.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(isSelected ? .white : .primary)
            .background {
                if isSelected {
                    Capsule().fill(category.color.gradient)
                } else {
                    Capsule().fill(.ultraThinMaterial)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selected: ExpenseCategory = .food
        var body: some View {
            CategoryPickerView(selected: $selected)
        }
    }
    return PreviewWrapper()
}
