//
//  CategoryIcon.swift
//  Equipment Checkout Management System
//

import SwiftUI

/// Rounded tile showing the SF Symbol for an equipment category.
struct CategoryIcon: View {
    let category: EquipmentCategory?
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: category?.systemImage ?? "questionmark")
            .font(.system(size: size * 0.45))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.accentColor.gradient, in: .rect(cornerRadius: size * 0.25))
    }
}

#Preview {
    HStack {
        ForEach(EquipmentCategory.allCases) { category in
            CategoryIcon(category: category)
        }
    }
}
