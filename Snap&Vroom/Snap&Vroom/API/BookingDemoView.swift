//
//  ApiTest.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//

import SwiftUI
import Combine


// MARK: - View

struct BookingDemoView: View {
    @StateObject private var viewModel = BookingViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    // MARK: Booking Header
                    
                    if let booking = viewModel.booking {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Booking ID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(booking.id)
                                        .font(.headline)
                                        .foregroundColor(.blue)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                
                                Spacer()
                                
                                Button {
                                    Task { await viewModel.fetchBooking() }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    viewModel.showBookingDetails.toggle()
                                }
                            }
                            
                            if viewModel.showBookingDetails {
                                Divider()
                                
                                if let imageUrl = booking.selectedVehicle?.vehicle.images?.first {
                                    AsyncImage(url: imageUrl) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxHeight: 160)
                                            .cornerRadius(8)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                }
                                
                                Text("\(booking.selectedVehicle?.vehicle.brand ?? "-") \(booking.selectedVehicle?.vehicle.model ?? "")")
                                    .font(.subheadline.bold())
                                
                                Text("Booked category: \(booking.bookedCategory ?? "-")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Status: \(booking.status ?? "-")")
                                    .font(.caption)

                                // Protection info from booking
                                if let protection = booking.protectionPackages?.first {
                                    Text("Protection: \(protection.name ?? "-")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                // Addon info from booking (local state stored on Booking)
                                if !booking.addons.isEmpty {
                                    Text("Addons:")
                                        .font(.caption)
                                    ForEach(booking.addons) { addon in
                                        Text("• \(addon.title) (\(addon.amount)x)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    } else {
                        Text("No booking yet. Create one to begin.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    
                    // MARK: API Buttons
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Actions")
                            .font(.headline)
                        
                        HStack {
                            Button("Create Booking") {
                                Task { await viewModel.createBooking() }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Get Booking") {
                                Task { await viewModel.fetchBooking() }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        HStack {
                            Button("Get Vehicles") {
                                Task { await viewModel.fetchVehicles() }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Get Protections") {
                                Task { await viewModel.fetchProtections() }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Get Addons") {
                                Task { await viewModel.fetchAddons() }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        HStack {
                            Button("Assign Selected Vehicle") {
                                Task { await viewModel.assignSelectedVehicle() }
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button("Assign Selected Protection") {
                                Task { await viewModel.assignSelectedProtection() }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Button("Complete Booking") {
                            Task { await viewModel.completeBooking() }
                        }
                        .buttonStyle(.bordered)
                        .tint(.green)
                    }
                    
                    // MARK: Selection Fields
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Selected IDs for Actions")
                            .font(.headline)
                        
                        VStack(alignment: .leading) {
                            Text("Vehicle ID to assign")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text((viewModel.selectedVehicleIdForAssign ?? "").isEmpty ? "None" : (viewModel.selectedVehicleIdForAssign ?? ""))
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Protection Package ID to assign")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text((viewModel.selectedProtectionIdForAssign ?? "").isEmpty ? "None" : (viewModel.selectedProtectionIdForAssign ?? ""))
                                .font(.footnote)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }

                        VStack(alignment: .leading) {
                            Text("Addons selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let booking = viewModel.booking, !booking.addons.isEmpty {
                                ForEach(booking.addons) { addon in
                                    Text("\(addon.title) [\(addon.id)] x\(addon.amount)")
                                        .font(.footnote)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                            } else {
                                Text("None")
                                    .font(.footnote)
                            }
                        }
                    }
                    
                    // MARK: Vehicles List
                    
                    if let dealsResponse = viewModel.vehiclesResponse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Available Vehicles (\(dealsResponse.totalVehicles ?? 0))")
                                .font(.headline)
                            
                            ForEach(dealsResponse.deals, id: \.vehicle.id) { deal in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text("\(deal.vehicle.brand ?? "-") \(deal.vehicle.model ?? "")")
                                                .font(.subheadline.bold())
                                            Text("ID: \(deal.vehicle.id)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            Text("Category: \(deal.vehicle.acrissCode ?? "-")")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Select") {
                                            Task { await viewModel.assignVehicle(vehicleId: deal.vehicle.id) }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    if let imageURL = deal.vehicle.images?.first {
                                        AsyncImage(url: imageURL) { image in
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(maxHeight: 120)
                                                .cornerRadius(6)
                                        } placeholder: {
                                            ProgressView()
                                        }
                                    }
                                    
                                    if let pricing = deal.pricing {
                                        let display = pricing.displayPrice
                                        Text("Display price: \(display.amount) \(display.currency) \(display.suffix ?? "")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // MARK: Protections List
                    
                    if let protections = viewModel.protectionsResponse {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Protection Packages")
                                .font(.headline)
                            
                            ForEach(protections.protectionPackages ?? [], id: \.id) { pkg in
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(pkg.name ?? "-")
                                                .font(.subheadline.bold())
                                            Text("ID: \(pkg.id)")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Button("Select") {
                                            Task { await viewModel.assignProtection(packageId: pkg.id) }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    
                                    if let desc = pkg.description {
                                        Text(desc)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("Rating: \(pkg.ratingStars ?? 0) ★")
                                        .font(.caption2)
                                    
                                    if let price = pkg.price?.displayPrice {
                                        Text("Price: \(price.amount) \(price.currency) \(price.suffix ?? "")")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(8)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(10)
                            }
                        }
                    }
                    
                    // MARK: Addons List
                    
                    if !viewModel.addonsResponse.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Addons")
                                .font(.headline)
                            
                            ForEach(viewModel.addonsResponse.indices, id: \.self) { idx in
                                let option = viewModel.addonsResponse[idx]
                                
                                if let price = option.additionalInfo?.price?.displayPrice {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(option.chargeDetail?.title ?? "-")
                                                    .font(.caption)
                                                Text(option.chargeDetail?.description ?? "")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                                Text("Price: \(price.amount) \(price.currency) \(price.suffix ?? "")")
                                                    .font(.caption2)
                                            }
                                            
                                            Spacer()
                                            
                                            if let addonId = option.chargeDetail?.id,
                                               let title = option.chargeDetail?.title {
                                                Button("Select") {
                                                    Task { await viewModel.assignAddon(addonId: addonId, title: title) }
                                                }
                                                .buttonStyle(.bordered)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(10)
                                }
                            }
                        }
                    }
                    
                    // MARK: Error / Loading
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Booking API Demo")
        }
    }
}

// MARK: - Preview

struct BookingDemoView_Previews: PreviewProvider {
    static var previews: some View {
        BookingDemoView()
    }
}
