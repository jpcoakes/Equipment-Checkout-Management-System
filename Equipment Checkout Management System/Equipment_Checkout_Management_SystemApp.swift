//
//  Equipment_Checkout_Management_SystemApp.swift
//  Equipment Checkout Management System
//
//  Created by Joel Coakes on 11/18/26.
//

import SwiftUI
import SwiftData

@main
struct Equipment_Checkout_Management_SystemApp: App {
    /// Persistent on-device store for all equipment, borrower, and checkout records.
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Equipment.self,
            Borrower.self,
            Checkout.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
