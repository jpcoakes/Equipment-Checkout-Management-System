//
//  ContentView.swift
//  Equipment Checkout Management System
//
//  Created by Joel Coakes on 11/18/26.
//

import SwiftUI
import SwiftData

/// Root navigation between the main sections of the app.
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Equipment", systemImage: "shippingbox.fill") {
                EquipmentListView()
            }
            Tab("Borrowers", systemImage: "person.2.fill") {
                BorrowerListView()
            }
            Tab("Checkouts", systemImage: "arrow.left.arrow.right") {
                CheckoutListView()
            }
            Tab("History", systemImage: "clock.arrow.circlepath") {
                HistoryView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewData.container)
}
