//
//  CheckoutListView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Lists active checkouts and lets the administrator start new checkouts
/// and process returns.
struct CheckoutListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Checkout.dueDate) private var checkouts: [Checkout]

    @State private var isCreatingCheckout = false
    @State private var checkoutToReturn: Checkout?
    @State private var errorMessage: String?

    private var activeCheckouts: [Checkout] {
        checkouts.filter { !$0.isReturned }
    }

    var body: some View {
        NavigationStack {
            Group {
                if activeCheckouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Active Checkouts", systemImage: "tray")
                    } description: {
                        Text("Equipment that is checked out to a borrower will appear here.")
                    } actions: {
                        Button("New Checkout") { isCreatingCheckout = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        Section {
                            ForEach(activeCheckouts) { checkout in
                                Button {
                                    checkoutToReturn = checkout
                                } label: {
                                    CheckoutRow(checkout: checkout)
                                }
                                .tint(.primary)
                                .swipeActions {
                                    Button("Return", systemImage: "arrow.uturn.backward") {
                                        checkoutToReturn = checkout
                                    }
                                    .tint(.green)
                                }
                            }
                        } header: {
                            let overdueCount = activeCheckouts.filter(\.isOverdue).count
                            if overdueCount > 0 {
                                Text("Checked Out (\(activeCheckouts.count)) · \(overdueCount) Overdue")
                            } else {
                                Text("Checked Out (\(activeCheckouts.count))")
                            }
                        } footer: {
                            Text("Tap a checkout to mark its equipment as returned.")
                        }
                    }
                }
            }
            .navigationTitle("Checkouts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Checkout", systemImage: "plus") {
                        isCreatingCheckout = true
                    }
                }
            }
            .sheet(isPresented: $isCreatingCheckout) {
                NewCheckoutView()
            }
            .confirmationDialog("Mark as Returned?", item: $checkoutToReturn) { checkout in
                Button("Return \(checkout.equipment?.name ?? "Equipment")", action: { processReturn(checkout) })
            } message: { checkout in
                Text("\(checkout.equipment?.name ?? "This item") will be marked as returned by \(checkout.borrower?.fullName ?? "the borrower") today and become available again.")
            }
            .alert("Unable to Complete", item: $errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private func processReturn(_ checkout: Checkout) {
        do {
            try InventoryService(context: modelContext).returnCheckout(checkout)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    CheckoutListView()
        .modelContainer(PreviewData.container)
}
