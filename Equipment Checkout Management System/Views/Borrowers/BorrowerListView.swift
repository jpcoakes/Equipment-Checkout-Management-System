//
//  BorrowerListView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

struct BorrowerListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Borrower.fullName) private var borrowers: [Borrower]

    @State private var searchText = ""
    @State private var isAddingBorrower = false
    @State private var borrowerToDelete: Borrower?
    @State private var errorMessage: String?

    /// Matches on name, email, or department.
    private var filteredBorrowers: [Borrower] {
        let search = InventoryService.trimmed(searchText)
        guard !search.isEmpty else { return borrowers }
        return borrowers.filter {
            $0.fullName.localizedStandardContains(search)
                || $0.email.localizedStandardContains(search)
                || $0.department.localizedStandardContains(search)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if borrowers.isEmpty {
                    ContentUnavailableView {
                        Label("No Borrowers", systemImage: "person.2")
                    } description: {
                        Text("Register students and faculty before checking out equipment.")
                    } actions: {
                        Button("Register Borrower") { isAddingBorrower = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    borrowerList
                }
            }
            .navigationTitle("Borrowers")
            .navigationDestination(for: Borrower.self) { borrower in
                BorrowerDetailView(borrower: borrower)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Register Borrower", systemImage: "person.badge.plus") {
                        isAddingBorrower = true
                    }
                }
            }
            .sheet(isPresented: $isAddingBorrower) {
                BorrowerFormView(borrower: nil)
            }
            .confirmationDialog("Delete Borrower?", item: $borrowerToDelete) { borrower in
                Button("Delete \(borrower.fullName)", role: .destructive) {
                    delete(borrower)
                }
            } message: { borrower in
                Text("\(borrower.fullName) will be permanently removed.")
            }
            .alert("Unable to Complete", item: $errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private var borrowerList: some View {
        List {
            if filteredBorrowers.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ForEach(filteredBorrowers) { borrower in
                    NavigationLink(value: borrower) {
                        BorrowerRow(borrower: borrower)
                    }
                    .swipeActions {
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            requestDelete(borrower)
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search by name, email, or department")
    }

    private func requestDelete(_ borrower: Borrower) {
        if borrower.hasCheckoutHistory {
            errorMessage = InventoryError.borrowerHasHistory(borrower.fullName).localizedDescription
        } else {
            borrowerToDelete = borrower
        }
    }

    private func delete(_ borrower: Borrower) {
        do {
            try InventoryService(context: modelContext).deleteBorrower(borrower)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// A single row in the borrower list.
struct BorrowerRow: View {
    let borrower: Borrower

    var body: some View {
        HStack(spacing: 12) {
            InitialsAvatar(name: borrower.fullName)

            VStack(alignment: .leading, spacing: 2) {
                Text(borrower.fullName)
                    .font(.headline)
                Text(borrower.department)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            let count = borrower.activeCheckouts.count
            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.title3.bold())
                    .foregroundStyle(count > 0 ? Color.orange : Color.secondary)
                Text("checked out")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(.vertical, 4)
    }
}

/// Circular avatar showing a person's initials.
struct InitialsAvatar: View {
    let name: String
    var size: CGFloat = 44

    private var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.indigo.gradient, in: .circle)
            .accessibilityHidden(true)
    }
}

#Preview {
    BorrowerListView()
        .modelContainer(PreviewData.container)
}
