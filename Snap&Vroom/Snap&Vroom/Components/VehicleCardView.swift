//
//  CarThumbnail.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 22.11.25.
//

import SwiftUI

struct VehicleCardView: View {
    let selectedVehicle: SelectedVehicle?
    
    // Use the first image URL from the vehicle, just like your current carImageURL
    private var carImageURL: URL? {
        selectedVehicle?.vehicle.images?.first
    }
    
    var body: some View {
        guard let selectedVehicle else {
            print("Showing empty car view")
            return AnyView(EmptyView())
        }
        return AnyView(
            ZStack {
                // White base so gradient has contrast
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                
                // Sixt-style black → transparent gradient overlay
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.85),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.0)
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                
                // Car image
                AsyncImage(url: carImageURL) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6).opacity(0.3))
                            ProgressView()
                        }
                        
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(radius: 10, y: 6)
                        
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color(.systemGray6).opacity(0.3))
                            Image(systemName: "car.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                    @unknown default:
                        EmptyView()
                    }
                }
                
                // Optional: overlay basic vehicle info at the bottom
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(selectedVehicle.vehicle.brand ?? "") \(selectedVehicle.vehicle.model ?? "")")
                                .font(.headline)
                                .foregroundColor(.white)
                            if let groupType = selectedVehicle.vehicle.groupType {
                                Text(groupType)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        Spacer()
                    }
                    .padding()
                }
                
                // Attribute icons (top-right)
                HStack(spacing: 8) {
                    ForEach(selectedVehicle.vehicle.attributes ?? [], id: \.key) { attr in
                        if let iconURL = attr.iconUrl {
                            AsyncImage(url: iconURL) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                case .empty:
                                    ProgressView().frame(width: 24, height: 24)
                                case .failure:
                                    Image(systemName: "questionmark.circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white.opacity(0.7))
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
                .frame(height: 180)
        )
    }
}
