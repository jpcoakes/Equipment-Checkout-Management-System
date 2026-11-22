//
//  BorrowerFormView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Register a new borrower or edit an existing one.
struct BorrowerFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let borrower: Borrower?

    @State private var fullName: String
    @State private var email: String
    @State private var department: String
    @State private var errorMessage: String?

    init(borrower: Borrower?) {
        self.borrower = borrower
        self.fullName = borrower?.fullName ?? ""
        self.email = borrower?.email ?? ""
        self.department = borrower?.department ?? ""
    }

    /// Inline hint shown once the administrator has typed an email.
    private var showsEmailWarning: Bool {
        !InventoryService.trimmed(email).isEmpty && !InventoryService.isValidEmail(email)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)

                    TextField("Email Address", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    TextField("Department", text: $department)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Borrower Information")
                } footer: {
                    if showsEmailWarning {
                        Label("Enter a valid email address, such as name@university.edu.", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    } else {
                        Text("All fields are required.")
                    }
                }

                if let borrower {
                    Section("Record") {
                        LabeledContent("Borrower ID", value: borrower.displayID)
                    }
                }
            }
            .navigationTitle(borrower == nil ? "New Borrower" : "Edit Borrower")
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
                .saveBorrower(borrower, fullName: fullName, email: email, department: department)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    BorrowerFormView(borrower: nil)
        .modelContainer(PreviewData.container)
}
