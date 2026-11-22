//
//  EquipmentFormView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Add or edit an equipment record. Availability is intentionally not
/// editable here; it is derived from checkout records.
struct EquipmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let equipment: Equipment?

    @State private var name: String
    @State private var category: EquipmentCategory
    @State private var condition: EquipmentCondition
    @State private var errorMessage: String?

    init(equipment: Equipment?) {
        self.equipment = equipment
        self.name = equipment?.name ?? ""
        self.category = equipment?.category ?? .laptop
        self.condition = equipment?.condition ?? .good
    }

    private var isEditing: Bool { equipment != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Equipment Name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $category) {
                        ForEach(EquipmentCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(category)
                        }
                    }

                    Picker("Condition", selection: $condition) {
                        ForEach(EquipmentCondition.allCases) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                }

                if let equipment {
                    Section {
                        LabeledContent("Equipment ID", value: equipment.displayID)
                        LabeledContent("Availability") {
                            StatusBadge.availability(equipment.isAvailable)
                        }
                        if let active = equipment.activeCheckout {
                            LabeledContent("Borrower", value: active.borrower?.fullName ?? "Unknown")
                            LabeledContent("Due", value: active.dueDate.formatted(date: .abbreviated, time: .omitted))
                        }
                        LabeledContent("Total Checkouts", value: "\(equipment.checkouts.count)")
                    } header: {
                        Text("Status")
                    } footer: {
                        Text("Availability updates automatically when the item is checked out or returned.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Equipment" : "New Equipment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", role: .confirm, action: save)
                }
            }
            .alert("Unable to Save", item: $errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private func save() {
        do {
            try InventoryService(context: modelContext)
                .saveEquipment(equipment, name: name, category: category, condition: condition)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EquipmentFormView(equipment: nil)
        .modelContainer(PreviewData.container)
}
