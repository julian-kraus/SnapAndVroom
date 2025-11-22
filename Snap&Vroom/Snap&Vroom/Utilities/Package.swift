//
//  Package.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import Foundation

struct Package: Hashable {
    let name: String
    let image: String
    let description: String
    let originalPrice: Double
    let discountedPrice: Double
    let isPrimary: Bool
}
