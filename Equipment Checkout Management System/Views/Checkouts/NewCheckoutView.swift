//
//  NewCheckoutView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Assigns an available equipment item to a registered borrower.
struct NewCheckoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \Borrower.fullName) private var borrowers: [Borrower]
    @Query(sort: \Equipment.name) private var equipment: [Equipment]

    @State private var selectedBorrower: Borrower?
    @State private var selectedEquipment: Equipment?
    @State private var checkoutDate = Date.now
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
    @State private var isConfirming = false
    @State private var errorMessage: String?

    /// Only equipment without an active checkout can be selected.
    private var availableEquipment: [Equipment] {
        equipment.filter(\.isAvailable)
    }

    private var isDueDateValid: Bool {
        InventoryService.isValidDueDate(dueDate, checkoutDate: checkoutDate)
    }

    private var canConfirm: Bool {
        selectedBorrower != nil && selectedEquipment != nil && isDueDateValid
    }

    var body: some View {
        NavigationStack {
            Form {
                borrowerSection
                equipmentSection
                datesSection
            }
            .navigationTitle("New Checkout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check Out", role: .confirm, action: requestConfirmation)
                }
            }
            .alert("Confirm Checkout", isPresented: $isConfirming) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm", action: createCheckout)
            } message: {
                Text(confirmationMessage)
            }
            .alert("Unable to Check Out", item: $errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private var borrowerSection: some View {
        Section("Borrower") {
            if borrowers.isEmpty {
                Label("No borrowers are registered. Add one in the Borrowers tab first.", systemImage: "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(.secondary)
            } else {
                Picker("Borrower", selection: $selectedBorrower) {
                    Text("Select a Borrower").tag(Borrower?.none)
                    ForEach(borrowers) { borrower in
                        Text("\(borrower.fullName) (\(borrower.department))")
                            .tag(Optional(borrower))
                    }
                }
            }
        }
    }

    private var equipmentSection: some View {
        Section {
            if availableEquipment.isEmpty {
                Label(
                    equipment.isEmpty
                        ? "No equipment has been added. Add some in the Equipment tab first."
                        : "All equipment is currently checked out.",
                    systemImage: "shippingbox"
                )
                .foregroundStyle(.secondary)
            } else {
                Picker("Equipment", selection: $selectedEquipment) {
                    Text("Select Equipment").tag(Equipment?.none)
                    ForEach(availableEquipment) { item in
                        Label("\(item.name) · \(item.condition.rawValue)", systemImage: item.category.systemImage)
                            .tag(Optional(item))
                    }
                }
            }
        } header: {
            Text("Equipment")
        } footer: {
            Text("Only available equipment is listed.")
        }
    }

    private var datesSection: some View {
        Section {
            DatePicker("Checkout Date", selection: $checkoutDate, displayedComponents: .date)
            DatePicker("Due Date", selection: $dueDate, displayedComponents: .date)
        } header: {
            Text("Dates")
        } footer: {
            if !isDueDateValid {
                Label("The due date must be later than the checkout date.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private var confirmationMessage: String {
        let equipmentName = selectedEquipment?.name ?? ""
        let borrowerName = selectedBorrower?.fullName ?? ""
        let due = dueDate.formatted(date: .abbreviated, time: .omitted)
        return "Check out \(equipmentName) to \(borrowerName), due \(due)?"
    }

    /// Validates the form before showing the confirmation prompt so the
    /// administrator gets a specific message about what is missing.
    private func requestConfirmation() {
        if selectedBorrower == nil {
            errorMessage = InventoryError.noBorrowerSelected.localizedDescription
        } else if selectedEquipment == nil {
            errorMessage = InventoryError.noEquipmentSelected.localizedDescription
        } else if let item = selectedEquipment, !item.isAvailable {
            errorMessage = InventoryError.equipmentUnavailable(item.name).localizedDescription
        } else if !isDueDateValid {
            errorMessage = InventoryError.invalidDueDate.localizedDescription
        } else {
            isConfirming = true
        }
    }

    private func createCheckout() {
        do {
            try InventoryService(context: modelContext).createCheckout(
                borrower: selectedBorrower,
                equipment: selectedEquipment,
                checkoutDate: checkoutDate,
                dueDate: dueDate
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    NewCheckoutView()
        .modelContainer(PreviewData.container)
}
