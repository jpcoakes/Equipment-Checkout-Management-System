//
//  InventoryService.swift
//  Equipment Checkout Management System
//

import Foundation
import SwiftData

/// Errors raised when an operation violates a business rule.
/// Each case carries a message suitable for showing to the administrator.
enum InventoryError: LocalizedError {
    case missingField(String)
    case invalidEmail
    case noBorrowerSelected
    case noEquipmentSelected
    case equipmentUnavailable(String)
    case invalidDueDate
    case alreadyReturned
    case equipmentHasHistory(String)
    case borrowerHasHistory(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingField(let field):
            "\(field) cannot be empty."
        case .invalidEmail:
            "Please enter a valid email address (for example, name@university.edu)."
        case .noBorrowerSelected:
            "Select a registered borrower before confirming the checkout."
        case .noEquipmentSelected:
            "Select an available equipment item before confirming the checkout."
        case .equipmentUnavailable(let name):
            "\(name) is already checked out and cannot be checked out again until it is returned."
        case .invalidDueDate:
            "The due date must be later than the checkout date."
        case .alreadyReturned:
            "This checkout has already been returned."
        case .equipmentHasHistory(let name):
            "\(name) has checkout history and cannot be deleted. You can still edit its details."
        case .borrowerHasHistory(let name):
            "\(name) has checkout history and cannot be deleted, because those transactions must stay linked to this borrower."
        case .saveFailed(let reason):
            "The change could not be saved. \(reason)"
        }
    }
}

/// Central place for creating, updating, and deleting records so the
/// business rules are enforced consistently regardless of which screen
/// triggers the action.
struct InventoryService {
    let context: ModelContext

    static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func isValidEmail(_ email: String) -> Bool {
        let pattern = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/
        return trimmed(email).wholeMatch(of: pattern) != nil
    }

    func saveEquipment(
        _ existing: Equipment?,
        name: String,
        category: EquipmentCategory,
        condition: EquipmentCondition
    ) throws {
        let name = Self.trimmed(name)
        guard !name.isEmpty else { throw InventoryError.missingField("Equipment name") }

        if let existing {
            existing.name = name
            existing.category = category
            existing.condition = condition
        } else {
            context.insert(Equipment(name: name, category: category, condition: condition))
        }
        try save()
    }

    func deleteEquipment(_ equipment: Equipment) throws {
        guard !equipment.hasCheckoutHistory else {
            throw InventoryError.equipmentHasHistory(equipment.name)
        }
        context.delete(equipment)
        try save()
    }

    func saveBorrower(
        _ existing: Borrower?,
        fullName: String,
        email: String,
        department: String
    ) throws {
        let fullName = Self.trimmed(fullName)
        let email = Self.trimmed(email)
        let department = Self.trimmed(department)

        guard !fullName.isEmpty else { throw InventoryError.missingField("Full name") }
        guard !email.isEmpty else { throw InventoryError.missingField("Email address") }
        guard Self.isValidEmail(email) else { throw InventoryError.invalidEmail }
        guard !department.isEmpty else { throw InventoryError.missingField("Department") }

        if let existing {
            existing.fullName = fullName
            existing.email = email
            existing.department = department
        } else {
            context.insert(Borrower(fullName: fullName, email: email, department: department))
        }
        try save()
    }

    func deleteBorrower(_ borrower: Borrower) throws {
        guard !borrower.hasCheckoutHistory else {
            throw InventoryError.borrowerHasHistory(borrower.fullName)
        }
        context.delete(borrower)
        try save()
    }

    /// Validates that the due date falls on a later calendar day than the checkout date.
    static func isValidDueDate(_ dueDate: Date, checkoutDate: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.startOfDay(for: dueDate) > calendar.startOfDay(for: checkoutDate)
    }

    @discardableResult
    func createCheckout(
        borrower: Borrower?,
        equipment: Equipment?,
        checkoutDate: Date,
        dueDate: Date
    ) throws -> Checkout {
        guard let borrower else { throw InventoryError.noBorrowerSelected }
        guard let equipment else { throw InventoryError.noEquipmentSelected }
        // Re-check availability at confirmation time to prevent duplicate active checkouts.
        guard equipment.isAvailable else { throw InventoryError.equipmentUnavailable(equipment.name) }
        guard Self.isValidDueDate(dueDate, checkoutDate: checkoutDate) else {
            throw InventoryError.invalidDueDate
        }

        let checkout = Checkout(
            equipment: equipment,
            borrower: borrower,
            checkoutDate: checkoutDate,
            dueDate: dueDate
        )
        context.insert(checkout)
        try save()
        return checkout
    }

    /// Marks a single checkout as returned. Other checkout records are untouched.
    func returnCheckout(_ checkout: Checkout, on returnDate: Date = .now) throws {
        guard !checkout.isReturned else { throw InventoryError.alreadyReturned }
        checkout.returnDate = returnDate
        checkout.status = .returned
        try save()
    }

    private func save() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw InventoryError.saveFailed(error.localizedDescription)
        }
    }
}
