//
//  Checkout.swift
//  Equipment Checkout Management System
//

import Foundation
import SwiftData

/// The lifecycle state of a checkout transaction.
enum CheckoutStatus: String, Codable {
    case active = "Active"
    case returned = "Returned"
}

/// The status shown to the administrator. Unlike `CheckoutStatus`, this is
/// never stored: overdue is derived from the stored due date each time.
enum CheckoutDisplayStatus: String, CaseIterable, Identifiable {
    case active = "Active"
    case overdue = "Overdue"
    case returned = "Returned"

    var id: String { rawValue }
}

/// One equipment item assigned to one borrower.
@Model
final class Checkout {
    /// Unique identifier for the checkout transaction.
    @Attribute(.unique) var checkoutID: UUID
    var checkoutDate: Date
    var dueDate: Date
    /// Set when the equipment is returned; `nil` while the checkout is active.
    var returnDate: Date?
    var statusRaw: String

    /// Related records. Display information is always read through these
    /// relationships so edits to equipment or borrowers appear everywhere.
    var equipment: Equipment?
    var borrower: Borrower?

    init(equipment: Equipment, borrower: Borrower, checkoutDate: Date, dueDate: Date) {
        self.checkoutID = UUID()
        self.equipment = equipment
        self.borrower = borrower
        self.checkoutDate = checkoutDate
        self.dueDate = dueDate
        self.returnDate = nil
        self.statusRaw = CheckoutStatus.active.rawValue
    }

    var status: CheckoutStatus {
        get { CheckoutStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var isReturned: Bool {
        status == .returned
    }

    /// Not returned and the due date is a calendar day earlier than today,
    /// so an item due today is still within its borrowing period.
    var isOverdue: Bool {
        guard !isReturned else { return false }
        let calendar = Calendar.current
        return calendar.startOfDay(for: dueDate) < calendar.startOfDay(for: .now)
    }

    /// Number of whole days past the due date (0 when not overdue).
    var daysOverdue: Int {
        guard isOverdue else { return 0 }
        let calendar = Calendar.current
        let days = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: dueDate),
            to: calendar.startOfDay(for: .now)
        ).day
        return days ?? 0
    }

    var displayStatus: CheckoutDisplayStatus {
        if isReturned { return .returned }
        return isOverdue ? .overdue : .active
    }

    var displayID: String {
        "CO-" + checkoutID.uuidString.prefix(8)
    }
}
