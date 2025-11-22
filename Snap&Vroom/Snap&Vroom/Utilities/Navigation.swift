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
    
    let apiClient = SixtAPIClient()
        
    // Booking context
    @Published var currentBooking: Booking?
    @Published var availableVehicles: VehicleDealsResponse?
    @Published var availableAddons: [AddonOption]?
    @Published var availableProtectionPackages: ProtectionPackagesResponse?
        
    
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


extension Navigation {
    @MainActor
    func initializeBooking() async {
        do {
            let booking = try await apiClient.createBooking()
            self.currentBooking = booking
            
            let bookingId = booking.id
            
            async let vehiclesTask = apiClient.getAvailableVehicles(for: bookingId)
            async let addonsTask = apiClient.getAddons(for: bookingId)
            async let protectionsTask = apiClient.getProtectionPackages(for: bookingId)
            
            let (vehicles, addons, protections) = try await (vehiclesTask, addonsTask, protectionsTask)
            
            self.availableVehicles = vehicles
            self.availableAddons = addons
            self.availableProtectionPackages = protections
            
            print("Booking initialized with id \(bookingId). Vehicles: \(vehicles.deals.count), Addons: \(addons.count ?? 0), Protections: \(protections.protectionPackages?.count ?? 0)")
        } catch {
            print("Failed to initialize booking:", error)
        }
    }
}
