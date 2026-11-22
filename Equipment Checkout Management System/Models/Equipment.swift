//
//  Equipment.swift
//  Equipment Checkout Management System
//

import Foundation
import SwiftData

/// The kinds of equipment the department lends out.
enum EquipmentCategory: String, CaseIterable, Identifiable, Codable {
    case laptop = "Laptop"
    case camera = "Camera"
    case tablet = "Tablet"
    case other = "Other"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .laptop: "laptopcomputer"
        case .camera: "camera.fill"
        case .tablet: "ipad"
        case .other: "shippingbox.fill"
        }
    }
}

/// The physical condition of an equipment item.
enum EquipmentCondition: String, CaseIterable, Identifiable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case damaged = "Damaged"

    var id: String { rawValue }
}

@Model
final class Equipment {
    /// Unique identifier for the equipment record.
    @Attribute(.unique) var equipmentID: UUID
    var name: String
    /// Stored as raw strings so they persist simply and can be used in predicates.
    var categoryRaw: String
    var conditionRaw: String
    var dateAdded: Date

    /// Every checkout transaction for this equipment (active and returned).
    @Relationship(inverse: \Checkout.equipment)
    var checkouts: [Checkout] = []

    init(name: String, category: EquipmentCategory, condition: EquipmentCondition) {
        self.equipmentID = UUID()
        self.name = name
        self.categoryRaw = category.rawValue
        self.conditionRaw = condition.rawValue
        self.dateAdded = .now
    }

    var category: EquipmentCategory {
        get { EquipmentCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var condition: EquipmentCondition {
        get { EquipmentCondition(rawValue: conditionRaw) ?? .good }
        set { conditionRaw = newValue.rawValue }
    }

    /// The checkout that has not yet been returned, if any.
    var activeCheckout: Checkout? {
        checkouts.first { !$0.isReturned }
    }

    /// Availability is derived from checkout records, never set manually.
    var isAvailable: Bool {
        activeCheckout == nil
    }

    var hasCheckoutHistory: Bool {
        !checkouts.isEmpty
    }

    /// Short form of the unique ID for display.
    var displayID: String {
        "EQ-" + equipmentID.uuidString.prefix(8)
    }
}
