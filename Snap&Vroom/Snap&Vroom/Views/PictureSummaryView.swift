//
//  PictureSummaryView.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//

import SwiftUI

struct PictureSummaryView: View {
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var pickupViewModel: PickupViewModel
    
    private let carImageURL = URL(string: "https://vehicle-pictures-prod.orange.sixt.com/143456/ffffff/18_1.png")
    
    var body: some View {
        ZStack {
            Color(.sixtOrange)
                .ignoresSafeArea()
            
            VStack {
                Spacer(minLength: 32)
                
                // Main content card
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("You're ready to go")
                            .font(.headline)
                            .textCase(.uppercase)
                            .foregroundColor(.secondary)
                        
                        Text("Let’s start your trip with your selected car.")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // User photo
                    if let image = pickupViewModel.capturedImage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your souvenir photo")
                                .font(.subheadline.weight(.semibold))
                            
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 220)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                )
                                .shadow(radius: 8, y: 4)
                        }
                        .padding(.horizontal)
                    } else {
                        EmptyView()
                            .frame(height: 0)
                    }
                    
                    // Car image
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Sixt car")
                            .font(.subheadline.weight(.semibold))

                        VehicleCardView(selectedVehicle: pickupViewModel.getInitialCar())
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 8)
                    
                    // Primary action
                    Button {
                        navigation.goTo(
                            view: .packages(
                                packages: [],
                                booking: $pickupViewModel.currentBooking.wrappedValue! // FIX ME
                            )
                        )
                    } label: {
                        Text("Continue to your booking")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                HStack {
                    backButton
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(.white)
        }
    }
}
