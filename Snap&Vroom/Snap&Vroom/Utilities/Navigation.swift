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
    
    @Published var capturedImage: UIImage? = nil
    
    @Published var carPreferencePrediction: CarPreferencePrediction? = nil

    let apiClient = SixtAPIClient()
        
    // Booking context
    @Published var currentBooking: Booking?
    @Published var availableVehicles: VehicleDealsResponse?
    @Published var availableAddons: [AddonOption]?
    @Published var availableProtectionPackages: ProtectionPackagesResponse?
        
    
    /// Returns a random vehicle whose acrissCode matches the booking's bookedCategory
func getInitialCar() -> SelectedVehicle? {
        print("[getInitialCar] Starting initial car selection...")
        print(currentBooking)
        print(availableVehicles?.deals.count as Any)
    print(currentBooking?.bookedCategory as Any)
        guard
            let booking = currentBooking,
            let bookedCategory = booking.bookedCategory,
            let deals = availableVehicles?.deals
        else {
            return nil
        }

        print("[getInitialCar] bookedCategory = \(bookedCategory)")
        print("[getInitialCar] total deals = \(deals.count)")

        // Filter vehicles that share the acrissCode
        let matching = deals.filter { deal in
            deal.vehicle.acrissCode == bookedCategory
        }

        print("[getInitialCar] matching deals for acrissCode = \(matching.count)")

        // Return a random one or nil if none match
        let chosen = matching.randomElement() ?? deals.randomElement()
        if let chosen = chosen {
            print("[getInitialCar] Selected vehicle id = \(chosen.vehicle.id)")
        } else {
            print("[getInitialCar] No vehicle could be selected.")
        }
        return chosen
    }

    enum View: Hashable {
        case pickup
        case camera
        case packages
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


extension Navigation {
    @MainActor
    func initializeBooking() async {
        do {
            // 1) Create a booking to get the id
            let createdBooking = try await apiClient.createBooking()
            let bookingId = createdBooking.id
            
            // 2) Fetch the full booking details (with bookedCategory, status, etc.)
            let fullBooking = try await apiClient.getBooking(id: bookingId)
            self.currentBooking = fullBooking
            
            // 3) Fetch related data in parallel
            async let vehiclesTask = apiClient.getAvailableVehicles(for: bookingId)
            async let addonsTask = apiClient.getAddons(for: bookingId)
            async let protectionsTask = apiClient.getProtectionPackages(for: bookingId)
            
            let (vehicles, addons, protections) = try await (vehiclesTask, addonsTask, protectionsTask)
            
            self.availableVehicles = vehicles
            self.availableAddons = addons
            self.availableProtectionPackages = protections
            
            print("Booking initialized with id \(bookingId). Vehicles: \(vehicles.deals.count), Addons: \(addons.count), Protections: \(protections.protectionPackages?.count ?? 0))")
            print("[initializeBooking] fullBooking.bookedCategory = \(fullBooking.bookedCategory ?? "nil")")
        } catch {
            print("Failed to initialize booking:", error)
        }
    }
}
