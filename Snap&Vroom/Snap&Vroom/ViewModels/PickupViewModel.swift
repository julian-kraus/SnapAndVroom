//
//  PickupViewModel.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import Foundation
import SwiftUI
import Combine

class PickupViewModel: ObservableObject {
    @Published var capturedImage: UIImage? = nil
    @Published var carPreferencePrediction: CarPreferencePrediction? = nil
    // Booking context
    @Published var currentBooking: Booking?
    @Published var availableVehicles: VehicleDealsResponse?
    @Published var availableAddons: [AddonOption]?
    @Published var availableProtectionPackages: ProtectionPackagesResponse?
    
    let apiClient = SixtAPIClient()
    
    
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
}

extension PickupViewModel {
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

    /// Builds a textual booking context with booking, vehicles, protections and addons
    /// to pass into the AI. Uses the data stored on Navigation.
    func makeBookingContext(userDescription: String? = nil) -> String {
        var lines: [String] = []

        // Optional high-level user / trip description
        if let userDescription, !userDescription.isEmpty {
            lines.append("USER_DESCRIPTION:")
            lines.append(userDescription)
            lines.append("")
        }

        // Booking basic info
        lines.append("BOOKING:")
        if let booking = currentBooking {
            lines.append("- id: \(booking.id)")
            lines.append("- bookedCategory: \(booking.bookedCategory ?? "unknown")")
            lines.append("- status: \(booking.status ?? "unknown")")
            lines.append("- createdAt: \(booking.createdAt ?? "unknown")")
        } else {
            lines.append("- none (booking not loaded)")
        }
        lines.append("")

        // Initial selected car (either getInitialCar or first deal)
        lines.append("INITIAL_SELECTED_CAR:")
        if let primaryVehicle = getInitialCar() ?? availableVehicles?.deals.first {
            let v = primaryVehicle.vehicle
            lines.append("- id: \(v.id)")
            lines.append("- name: \((v.brand ?? "") + " " + (v.model ?? ""))")
            lines.append("- acrissCode: \(v.acrissCode ?? "unknown")")
            lines.append("- groupType: \(v.groupType ?? "unknown")")
            lines.append("- passengersCount: \(v.passengersCount.map(String.init) ?? "unknown")")
            lines.append("- bagsCount: \(v.bagsCount.map(String.init) ?? "unknown")")
            lines.append("- fuelType: \(v.fuelType ?? "unknown")")
            lines.append("- transmissionType: \(v.transmissionType ?? "unknown")")
            if let price = primaryVehicle.pricing?.displayPrice {
                lines.append("- price: \(price.amount) \(price.currency) \(price.suffix ?? "")")
            }
            if let isRecommended = v.isRecommended {
                lines.append("- isRecommended: \(isRecommended)")
            }
            if let isMoreLuxury = v.isMoreLuxury {
                lines.append("- isMoreLuxury: \(isMoreLuxury)")
            }
            if let isExcitingDiscount = v.isExcitingDiscount {
                lines.append("- isExcitingDiscount: \(isExcitingDiscount)")
            }
        } else {
            lines.append("- none (no vehicles available)")
        }
        lines.append("")

        // All available vehicles
        lines.append("AVAILABLE_VEHICLES:")
        if let deals = availableVehicles?.deals, !deals.isEmpty {
            for deal in deals {
                let v = deal.vehicle
                var row = "- id: \(v.id)"
                if let brand = v.brand, let model = v.model {
                    row += ", name: \(brand) \(model)"
                }
                if let acriss = v.acrissCode {
                    row += ", acriss: \(acriss)"
                }
                if let groupType = v.groupType {
                    row += ", groupType: \(groupType)"
                }
                if let seats = v.passengersCount {
                    row += ", seats: \(seats)"
                }
                if let bags = v.bagsCount {
                    row += ", bags: \(bags)"
                }
                if let fuel = v.fuelType {
                    row += ", fuel: \(fuel)"
                }
                if let transmission = v.transmissionType {
                    row += ", transmission: \(transmission)"
                }
                if let price = deal.pricing?.displayPrice {
                    row += ", price: \(price.amount) \(price.currency) \(price.suffix ?? "")"
                }
                if let info = deal.dealInfo {
                    row += ", dealInfo: \(info)"
                }
                if let recommended = v.isRecommended {
                    row += ", isRecommended: \(recommended)"
                }
                if let moreLuxury = v.isMoreLuxury {
                    row += ", isMoreLuxury: \(moreLuxury)"
                }
                if let exciting = v.isExcitingDiscount {
                    row += ", isExcitingDiscount: \(exciting)"
                }
                lines.append(row)
            }
        } else {
            lines.append("- none")
        }
        lines.append("")

        // Protection packages
        lines.append("PROTECTION_PACKAGES:")
        if let packages = availableProtectionPackages?.protectionPackages, !packages.isEmpty {
            for p in packages {
                var row = "- id: \(p.id)"
                if let name = p.name {
                    row += ", name: \(name)"
                }
                if let stars = p.ratingStars {
                    row += ", ratingStars: \(stars)"
                }
                if let deductible = p.deductibleAmount {
                    row += ", deductible: \(deductible.value) \(deductible.currency)"
                }
                if let price = p.price?.displayPrice {
                    row += ", price: \(price.amount) \(price.currency) \(price.suffix ?? "")"
                }
                if let selected = p.isSelected {
                    row += ", isSelected: \(selected)"
                }
                lines.append(row)
            }
        } else {
            lines.append("- none")
        }
        lines.append("")

        // Addons
        lines.append("ADDONS:")
        if let addons = availableAddons, !addons.isEmpty {
            for option in addons {
                guard let detail = option.chargeDetail else { continue }
                var row = "- id: \(detail.id)"
                if let title = detail.title {
                    row += ", title: \(title)"
                }
                if let price = option.additionalInfo?.price?.displayPrice {
                    row += ", price: \(price.amount) \(price.currency) \(price.suffix ?? "")"
                }
                if let enabled = option.additionalInfo?.isEnabled {
                    row += ", isEnabled: \(enabled)"
                }
                lines.append(row)
            }
        } else {
            lines.append("- none")
        }
        var context = lines.joined(separator: "\n")
        print(context)
        return context
    }
}
