//
//  PackagesView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI

struct PackagesView: View {
    @EnvironmentObject private var navigation: Navigation
    private let package: Package
    private let booking: Booking
    
    init(package: Package,
         booking: Booking) {
        self.package = package
        self.booking = booking
    }
    
    var body: some View {
        VStack {
            Button {
                navigation.goTo(view: .addons)
            } label: {
                packageImage
                    .overlay(textAndPrice, alignment: .bottom)
            }
        }
    }
    
    var textAndPrice: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                packageText
                Spacer()
                packagePrice
            }
            Text(package.description)
                .font(.subheadline)
                .lineSpacing(0)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding()
    }
    
    var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            Text("Previous")
        }
    }
    
    var packageImage: some View {
        Image(package.image)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: 400)
            .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.0)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .allowsHitTesting(false)
    }
    
    var packageText: some View {
            Text(package.name)
                .font(.title2)
                .bold()
                .foregroundStyle(.sixtOrange)
    }
    
    var packagePrice: some View {
        HStack(spacing: 6) {
            Text(package.discountedPrice, format: .currency(code: "EUR"))
                .font(.headline)
                .foregroundStyle(.sixtOrange)

            Text(package.originalPrice, format: .currency(code: "EUR"))
                .foregroundColor(Color(.systemGray4))
                .strikethrough()
        }
    }
}
