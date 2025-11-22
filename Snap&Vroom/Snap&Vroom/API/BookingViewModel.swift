//
//  ApiDemoView.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//

import SwiftUI
import Combine


// MARK: - ViewModel

@MainActor
final class BookingViewModel: ObservableObject {
    private let api = SixtAPIClient()
    
    // Core data
    @Published var booking: Booking?
    @Published var vehiclesResponse: VehicleDealsResponse?
    @Published var protectionsResponse: ProtectionPackagesResponse?
    @Published var addonsResponse: AddonsResponse?
    
    // ID selection for actions
    @Published var selectedVehicleIdForAssign: String? = nil
    @Published var selectedProtectionIdForAssign: String? = nil

    // Helper to merge server booking while preserving local addons
    private func applyServerBooking(_ serverBooking: Booking) {
        var merged = serverBooking
        if let current = booking {
            merged.addons = current.addons
        }
        booking = merged
    }

    func assignProtection(packageId: String) async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }

        // update selected id for UI
        selectedProtectionIdForAssign = packageId

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let updated = try await api.assignProtectionPackage(
                bookingId: bookingId,
                packageId: packageId
            )
            applyServerBooking(updated)
        } catch {
            self.errorMessage = "Assign protection failed: \(error)"
        }
    }

    func assignAddon(addonId: String, title: String, amount: Int = 1) async {
        guard let currentBooking = booking else {
            errorMessage = "No booking ID yet."
            return
        }

        var updatedBooking = currentBooking

        // update booking's addons list (accumulate amounts per addon)
        if let index = updatedBooking.addons.firstIndex(where: { $0.id == addonId }) {
            updatedBooking.addons[index].amount += amount
        } else {
            updatedBooking.addons.append(BookingAddon(id: addonId, title: title, amount: amount))
        }

        booking = updatedBooking

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let serverUpdated = try await api.assignAddon(
                bookingId: updatedBooking.id,
                addonId: addonId,
                amount: amount
            )
            applyServerBooking(serverUpdated)
        } catch {
            self.errorMessage = "Assign addon failed: \(error)"
        }
    }
    
    // UI state
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showBookingDetails: Bool = true
    
    // MARK: - Actions
    
    func createBooking() async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Adjust this request body to match your backend requirements
            let req = CreateBookingRequest(
                pickupStation: nil,
                dropoffStation: nil,
                pickupDateTime: nil,
                dropoffDateTime: nil,
                bookedCategory: "CDAR"
            )
            let newBooking = try await api.createBooking(req)
            applyServerBooking(newBooking)
            self.selectedVehicleIdForAssign = nil
        } catch {
            self.errorMessage = "Create booking failed: \(error)"
        }
    }
    
    func fetchBooking() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetched = try await api.getBooking(id: bookingId)
            applyServerBooking(fetched)
        } catch {
            self.errorMessage = "Get booking failed: \(error)"
        }
    }
    
    func fetchVehicles() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let res = try await api.getAvailableVehicles(for: bookingId)
            self.vehiclesResponse = res
        } catch {
            self.errorMessage = "Get vehicles failed: \(error)"
        }
    }
    
    func fetchProtections() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let res = try await api.getProtectionPackages(for: bookingId)
            self.protectionsResponse = res
        } catch {
            self.errorMessage = "Get protections failed: \(error)"
        }
    }
    
    func fetchAddons() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let res = try await api.getAddons(for: bookingId)
            self.addonsResponse = res
        } catch {
            self.errorMessage = "Get addons failed: \(error)"
        }
    }
    
    func assignVehicle(vehicleId: String) async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }

        // update selected id for UI
        selectedVehicleIdForAssign = vehicleId

        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let updated = try await api.assignVehicle(
                bookingId: bookingId,
                vehicleId: vehicleId
            )
            applyServerBooking(updated)
        } catch {
            self.errorMessage = "Assign vehicle failed: \(error)"
        }
    }

    func assignSelectedVehicle() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        guard let vehicleId = selectedVehicleIdForAssign else {
            errorMessage = "No vehicle selected."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updated = try await api.assignVehicle(
                bookingId: bookingId,
                vehicleId: vehicleId
            )
            applyServerBooking(updated)
        } catch {
            self.errorMessage = "Assign vehicle failed: \(error)"
        }
    }
    
    func assignSelectedProtection() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        guard let packageId = selectedProtectionIdForAssign, !packageId.isEmpty else {
            errorMessage = "No protection package selected."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let updated = try await api.assignProtectionPackage(
                bookingId: bookingId,
                packageId: packageId
            )
            applyServerBooking(updated)
        } catch {
            self.errorMessage = "Assign protection failed: \(error)"
        }
    }
    
    func completeBooking() async {
        guard let bookingId = booking?.id else {
            errorMessage = "No booking ID yet."
            return
        }
        
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        
        do {
            let completed = try await api.completeBooking(bookingId: bookingId)
            applyServerBooking(completed)
        } catch {
            self.errorMessage = "Complete booking failed: \(error)"
        }
    }
}
