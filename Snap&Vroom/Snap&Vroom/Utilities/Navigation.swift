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
    var objectWillChange: ObservableObjectPublisher
    
    
    @Published var navPath = NavigationPath()
    
    init() {
        objectWillChange = .init();
    }
    
    enum View: Hashable {
        case pickup
        case camera
        case packages
        case addons
        case car
        case insurance
        case confirmation
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
