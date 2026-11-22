//
//  BorrowerDetailView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Shows a borrower's contact information, current checkouts, and past transactions.
struct BorrowerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let borrower: Borrower

    @State private var isEditing = false
    @State private var checkoutToReturn: Checkout?
    @State private var isConfirmingDelete = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    InitialsAvatar(name: borrower.fullName, size: 64)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(borrower.fullName)
                            .font(.title2.bold())
                        Text(borrower.displayID)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Contact Information") {
                LabeledContent {
                    Text(borrower.email)
                        .textSelection(.enabled)
                } label: {
                    Label("Email", systemImage: "envelope.fill")
                }
                LabeledContent {
                    Text(borrower.department)
                } label: {
                    Label("Department", systemImage: "building.2.fill")
                }
            }

            Section {
                if borrower.activeCheckouts.isEmpty {
                    Text("No equipment currently checked out.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(borrower.activeCheckouts) { checkout in
                        CheckoutRow(checkout: checkout, showsBorrower: false)
                            .swipeActions {
                                Button("Return", systemImage: "arrow.uturn.backward") {
                                    checkoutToReturn = checkout
                                }
                                .tint(.green)
                            }
                    }
                }
            } header: {
                Text("Currently Borrowed (\(borrower.activeCheckouts.count))")
            }

            Section {
                if borrower.returnedCheckouts.isEmpty {
                    Text("No previous checkouts.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(borrower.returnedCheckouts) { checkout in
                        CheckoutRow(checkout: checkout, showsBorrower: false)
                    }
                }
            } header: {
                Text("Previous Checkouts (\(borrower.returnedCheckouts.count))")
            }

            Section {
                Button("Delete Borrower", systemImage: "trash", role: .destructive) {
                    if borrower.hasCheckoutHistory {
                        errorMessage = InventoryError.borrowerHasHistory(borrower.fullName).localizedDescription
                    } else {
                        isConfirmingDelete = true
                    }
                }
            } footer: {
                if borrower.hasCheckoutHistory {
                    Text("Borrowers with checkout history cannot be deleted.")
                }
            }
        }
        .navigationTitle("Borrower")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) {
            BorrowerFormView(borrower: borrower)
        }
        .confirmationDialog("Mark as Returned?", item: $checkoutToReturn) { checkout in
            Button("Return \(checkout.equipment?.name ?? "Equipment")") {
                processReturn(checkout)
            }
        } message: { checkout in
            Text("Today's date will be recorded as the return date.")
        }
        .confirmationDialog("Delete Borrower?", isPresented: $isConfirmingDelete) {
            Button("Delete \(borrower.fullName)", role: .destructive, action: deleteBorrower)
        } message: {
            Text("\(borrower.fullName) will be permanently removed.")
        }
        .alert("Unable to Complete", item: $errorMessage) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    private func processReturn(_ checkout: Checkout) {
        do {
            try InventoryService(context: modelContext).returnCheckout(checkout)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteBorrower() {
        do {
            try InventoryService(context: modelContext).deleteBorrower(borrower)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
