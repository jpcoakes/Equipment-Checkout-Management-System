//
//  CheckoutRow.swift
//  Equipment Checkout Management System
//

import SwiftUI

/// A list row describing one checkout transaction.
/// Equipment and borrower names are read through the relationships,
/// so edits to those records are reflected here automatically.
struct CheckoutRow: View {
    let checkout: Checkout
    /// Hide the borrower name when the row is already shown in a borrower's context.
    var showsBorrower = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(category: checkout.equipment?.category, size: 40)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(checkout.equipment?.name ?? "Unknown Equipment")
                        .font(.headline)
                    Spacer()
                    StatusBadge.checkout(checkout.displayStatus)
                }

                if showsBorrower {
                    Label(checkout.borrower?.fullName ?? "Unknown Borrower", systemImage: "person.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Grid(alignment: .leading, horizontalSpacing: 8, verticalSpacing: 2) {
                    dateRow("Checked out", checkout.checkoutDate)
                    dateRow("Due", checkout.dueDate)
                        .foregroundStyle(checkout.isOverdue ? Color.red : Color.primary)
                    if let returnDate = checkout.returnDate {
                        dateRow("Returned", returnDate)
                    }
                }
                .font(.caption)

                if checkout.isOverdue {
                    let days = checkout.daysOverdue
                    Text("\(days) \(days == 1 ? "day" : "days") overdue")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func dateRow(_ title: String, _ date: Date) -> some View {
        GridRow {
            Text(title)
                .foregroundStyle(.secondary)
            Text(date, format: .dateTime.month(.abbreviated).day().year())
        }
    }
}
