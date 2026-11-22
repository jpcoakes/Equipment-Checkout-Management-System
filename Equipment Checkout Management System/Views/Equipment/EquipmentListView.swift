//
//  EquipmentListView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Availability filter options. Availability is derived from checkouts,
/// so this filter is applied in memory rather than in the query.
enum AvailabilityFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case available = "Available"
    case checkedOut = "Checked Out"

    var id: String { rawValue }
}

struct EquipmentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Equipment.name) private var equipment: [Equipment]

    @State private var searchText = ""
    @State private var categoryFilter: EquipmentCategory?
    @State private var availabilityFilter: AvailabilityFilter = .all

    @State private var isAddingEquipment = false
    @State private var editingEquipment: Equipment?
    @State private var equipmentToDelete: Equipment?
    @State private var errorMessage: String?

    private var filteredEquipment: [Equipment] {
        let search = InventoryService.trimmed(searchText)
        return equipment.filter { item in
            let matchesSearch = search.isEmpty || item.name.localizedStandardContains(search)
            let matchesCategory = categoryFilter == nil || item.category == categoryFilter
            let matchesAvailability = switch availabilityFilter {
            case .all: true
            case .available: item.isAvailable
            case .checkedOut: !item.isAvailable
            }
            return matchesSearch && matchesCategory && matchesAvailability
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if equipment.isEmpty {
                    ContentUnavailableView {
                        Label("No Equipment", systemImage: "shippingbox")
                    } description: {
                        Text("Add laptops, cameras, tablets, and other devices so they can be checked out.")
                    } actions: {
                        Button("Add Equipment") { isAddingEquipment = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    equipmentList
                }
            }
            .navigationTitle("Equipment")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Equipment", systemImage: "plus") {
                        isAddingEquipment = true
                    }
                }
            }
            .sheet(isPresented: $isAddingEquipment) {
                EquipmentFormView(equipment: nil)
            }
            .sheet(item: $editingEquipment) { item in
                EquipmentFormView(equipment: item)
            }
            .confirmationDialog("Delete Equipment?", item: $equipmentToDelete) { item in
                Button("Delete \(item.name)", role: .destructive) {
                    delete(item)
                }
            } message: { item in
                Text("\(item.name) will be permanently removed.")
            }
            .alert("Unable to Complete", item: $errorMessage) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
        }
    }

    private var equipmentList: some View {
        List {
            Section {
                HStack {
                    Picker("Category", selection: $categoryFilter) {
                        Text("All Categories").tag(EquipmentCategory?.none)
                        ForEach(EquipmentCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.systemImage)
                                .tag(Optional(category))
                        }
                    }
                    Spacer()
                    Picker("Availability", selection: $availabilityFilter) {
                        ForEach(AvailabilityFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }

            Section {
                if filteredEquipment.isEmpty {
                    ContentUnavailableView(
                        "No Matching Equipment",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search or filter.")
                    )
                } else {
                    ForEach(filteredEquipment) { item in
                        Button {
                            editingEquipment = item
                        } label: {
                            EquipmentRow(equipment: item)
                        }
                        .tint(.primary)
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                requestDelete(item)
                            }
                        }
                    }
                }
            } header: {
                Text("\(filteredEquipment.count) of \(equipment.count) items")
            }
        }
        .searchable(text: $searchText, prompt: "Search equipment by name")
    }

    /// Checks the history rule before asking for confirmation, so the
    /// administrator gets an explanation instead of a confirmation prompt.
    private func requestDelete(_ item: Equipment) {
        if item.hasCheckoutHistory {
            errorMessage = InventoryError.equipmentHasHistory(item.name).localizedDescription
        } else {
            equipmentToDelete = item
        }
    }

    private func delete(_ item: Equipment) {
        do {
            try InventoryService(context: modelContext).deleteEquipment(item)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

/// A single row in the equipment list.
struct EquipmentRow: View {
    let equipment: Equipment

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: equipment.category)

            VStack(alignment: .leading, spacing: 4) {
                Text(equipment.name)
                    .font(.headline)
                Text("\(equipment.category.rawValue) · \(equipment.displayID)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                StatusBadge.condition(equipment.condition)
            }

            Spacer()

            StatusBadge.availability(equipment.isAvailable)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    EquipmentListView()
        .modelContainer(PreviewData.container)
}
