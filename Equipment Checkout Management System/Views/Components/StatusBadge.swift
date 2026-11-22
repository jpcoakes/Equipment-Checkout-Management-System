//
//  StatusBadge.swift
//  Equipment Checkout Management System
//

import SwiftUI

/// A small colored capsule used for availability and checkout status.
struct StatusBadge: View {
    let text: String
    let color: Color
    var systemImage: String?

    var body: some View {
        Label {
            Text(text)
        } icon: {
            if let systemImage {
                Image(systemName: systemImage)
            }
        }
        .labelStyle(.titleAndIcon)
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.15), in: .capsule)
    }
}

extension StatusBadge {
    /// Badge showing whether equipment is available or checked out.
    static func availability(_ isAvailable: Bool) -> StatusBadge {
        isAvailable
            ? StatusBadge(text: "Available", color: .green, systemImage: "checkmark.circle.fill")
            : StatusBadge(text: "Checked Out", color: .orange, systemImage: "clock.fill")
    }

    /// Badge showing a checkout transaction's status.
    static func checkout(_ status: CheckoutDisplayStatus) -> StatusBadge {
        switch status {
        case .active:
            StatusBadge(text: "Active", color: .blue, systemImage: "arrow.up.forward.circle.fill")
        case .overdue:
            StatusBadge(text: "Overdue", color: .red, systemImage: "exclamationmark.triangle.fill")
        case .returned:
            StatusBadge(text: "Returned", color: .gray, systemImage: "arrow.uturn.backward.circle.fill")
        }
    }

    /// Badge showing equipment condition.
    static func condition(_ condition: EquipmentCondition) -> StatusBadge {
        let color: Color = switch condition {
        case .excellent: .teal
        case .good: .mint
        case .fair: .yellow
        case .damaged: .red
        }
        return StatusBadge(text: condition.rawValue, color: color)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge.availability(true)
        StatusBadge.availability(false)
        StatusBadge.checkout(.active)
        StatusBadge.checkout(.overdue)
        StatusBadge.checkout(.returned)
        StatusBadge.condition(.damaged)
    }
}
