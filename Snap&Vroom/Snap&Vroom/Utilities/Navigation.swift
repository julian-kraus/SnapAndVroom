//
//  Navigation.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import Foundation
import SwiftUI
import Combine

class Navigation: ObservableObject {
    
    @Published var navPath = NavigationPath()
    
    enum View: Hashable {
        case pickup
        case camera
        case packages(packages: [Package], booking: Booking)
        case addons
        case car
        case insurance
        case confirmation
        case picture_summary
    }
    
    func goTo(view: View) {
        navPath.append(view)
    }
    
    func goBack() {
        navPath.removeLast()
    }
    
    func goToRoot() {
        navPath.removeLast(navPath.count)
    }
}

extension Binding: Equatable where Value: Equatable {
    public static func == (lhs: Binding<Value>, rhs: Binding<Value>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Binding: Hashable where Value: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.wrappedValue.hashValue)
    }
}


