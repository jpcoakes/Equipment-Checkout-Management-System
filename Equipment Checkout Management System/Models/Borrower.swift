//
//  Borrower.swift
//  Equipment Checkout Management System
//

import Foundation
import SwiftData

@Model
final class Borrower {
    /// Unique identifier for the borrower record.
    @Attribute(.unique) var borrowerID: UUID
    var fullName: String
    var email: String
    var department: String
    var dateRegistered: Date

    /// Every checkout transaction for this borrower (active and returned).
    @Relationship(inverse: \Checkout.borrower)
    var checkouts: [Checkout] = []

    init(fullName: String, email: String, department: String) {
        self.borrowerID = UUID()
        self.fullName = fullName
        self.email = email
        self.department = department
        self.dateRegistered = .now
    }

    var activeCheckouts: [Checkout] {
        checkouts
            .filter { !$0.isReturned }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var returnedCheckouts: [Checkout] {
        checkouts
            .filter(\.isReturned)
            .sorted { ($0.returnDate ?? .distantPast) > ($1.returnDate ?? .distantPast) }
    }

    var hasCheckoutHistory: Bool {
        !checkouts.isEmpty
    }

    var displayID: String {
        "BR-" + borrowerID.uuidString.prefix(8)
    }
}
