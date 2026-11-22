//
//  PreviewData.swift
//  Equipment Checkout Management System
//

import Foundation
import SwiftData

/// Sample data used only by SwiftUI previews.
enum PreviewData {
    static let container: ModelContainer = {
        do {
            let container = try ModelContainer(
                for: Equipment.self, Borrower.self, Checkout.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
            let context = container.mainContext

            let laptop = Equipment(name: "MacBook Pro 14\"", category: .laptop, condition: .excellent)
            let camera = Equipment(name: "Canon EOS R6", category: .camera, condition: .good)
            let tablet = Equipment(name: "iPad Air", category: .tablet, condition: .fair)
            [laptop, camera, tablet].forEach(context.insert)

            let borrower1 = Borrower(fullName: "Joel Coakes", email: "jcoakes@auburn.edu", department: "Computer Science")
            let borrower2 = Borrower(fullName: "Sam Chen", email: "schen@university.edu", department: "Journalism")
            [borrower1, borrower2].forEach(context.insert)

            let now = Date.now
            let day: TimeInterval = 86_400
            context.insert(Checkout(equipment: laptop, borrower: borrower1, checkoutDate: now, dueDate: now + 7 * day))
            context.insert(Checkout(equipment: tablet, borrower: borrower2, checkoutDate: now - 9 * day, dueDate: now - 2 * day))

            let returned = Checkout(equipment: camera, borrower: borrower2, checkoutDate: now - 10 * day, dueDate: now - 3 * day)
            returned.returnDate = now - 4 * day
            returned.status = .returned
            context.insert(returned)

            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }()
}
