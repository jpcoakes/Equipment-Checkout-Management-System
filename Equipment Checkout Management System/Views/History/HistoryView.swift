//
//  HistoryView.swift
//  Equipment Checkout Management System
//

import SwiftUI
import SwiftData

/// Filter options for the checkout history.
enum HistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
    case returned = "Returned"
    case overdue = "Overdue"

    var id: String { rawValue }

    func matches(_ checkout: Checkout) -> Bool {
        switch self {
        case .all: true
        case .active: checkout.displayStatus == .active
        case .returned: checkout.displayStatus == .returned
        case .overdue: checkout.displayStatus == .overdue
        }
    }
}

/// Every checkout transaction, active and returned, newest first.
struct HistoryView: View {
    @Query(sort: \Checkout.checkoutDate, order: .reverse) private var checkouts: [Checkout]

    @State private var filter: HistoryFilter = .all
    @State private var searchText = ""

    /// Search matches equipment or borrower names, read through the relationships.
    private var filteredCheckouts: [Checkout] {
        let search = InventoryService.trimmed(searchText)
        return checkouts.filter { checkout in
            let matchesSearch = search.isEmpty
                || (checkout.equipment?.name.localizedStandardContains(search) ?? false)
                || (checkout.borrower?.fullName.localizedStandardContains(search) ?? false)
            return filter.matches(checkout) && matchesSearch
        }
    }

    private func count(for filter: HistoryFilter) -> Int {
        checkouts.filter(filter.matches).count
    }

    var body: some View {
        NavigationStack {
            Group {
                if checkouts.isEmpty {
                    ContentUnavailableView(
                        "No Checkout History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Checkouts appear here once equipment is assigned to a borrower, and they stay here after the equipment is returned.")
                    )
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
        }
    }

    private var historyList: some View {
        List {
            Section {
                Picker("Filter", selection: $filter) {
                    ForEach(HistoryFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                if filteredCheckouts.isEmpty {
                    ContentUnavailableView(
                        "No Matching Records",
                        systemImage: "magnifyingglass",
                        description: Text(emptyMessage)
                    )
                } else {
                    ForEach(filteredCheckouts) { checkout in
                        CheckoutRow(checkout: checkout)
                    }
                }
            } header: {
                Text("\(filter.rawValue) (\(filteredCheckouts.count))")
            } footer: {
                if filter == .all, !filteredCheckouts.isEmpty {
                    Text("\(count(for: .active)) active · \(count(for: .overdue)) overdue · \(count(for: .returned)) returned")
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search equipment or borrower")
    }

    private var emptyMessage: String {
        if !InventoryService.trimmed(searchText).isEmpty {
            return "No \(filter == .all ? "" : filter.rawValue.lowercased() + " ")transactions match your search."
        }
        return switch filter {
        case .all: "There are no checkout transactions."
        case .active: "No checkouts are currently within their borrowing period."
        case .returned: "No equipment has been returned yet."
        case .overdue: "No equipment is overdue."
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(PreviewData.container)
}
