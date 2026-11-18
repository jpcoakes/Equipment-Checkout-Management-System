//
//  Item.swift
//  Equipment Checkout Management System
//
//  Created by Joel Coakes on 11/18/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
