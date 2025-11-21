//
//  Item.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 21.11.25.
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
