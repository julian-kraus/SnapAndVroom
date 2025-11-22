//
//  PackagesView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI

struct PackagesView: View {
    @EnvironmentObject private var navigation: Navigation
    private let packages: [Package]
    private let booking: Booking
    private let basicPackage: Package = .init(
        name: "Basic",
        image: "basic",
        description: "Proceed with previously selected add-ons.",
        originalPrice: 100,
        discountedPrice: 100,
        isPrimary: false
    )
    
    init(packages: [Package],
         booking: Booking) {
        self.packages = packages
        self.booking = booking
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                ForEach(packages, id: \.self) { package in
                    Button {
                    navigation.goTo(view: .addons)
                    } label: {
                        PackageView(package: package, addons: booking.addons)
                    }
                }
                basicPackageView
            }
            .frame(maxWidth: .infinity)
        }
        .scrollIndicators(.visible)
    }
    
    var basicPackageView: some View {
        Button {
            navigation.goTo(view: .addons)
        } label: {
            PackageView(package: basicPackage, addons: booking.addons)
        }
    }
    
    var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            Text("Previous")
        }
    }
}

struct PackageView: View {
    let package: Package
    let addons: [BookingAddon]
    
    var body: some View {
        VStack(spacing: 0) {
            packageImage
                .overlay(textAndPrice, alignment: .bottom)
            addonsText
        }
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    package.isPrimary ? .sixtOrange : .gray,
                    lineWidth: package.isPrimary ? 5 : 2
                )
        )
        .shadow(color: .sixtOrange.opacity(package.isPrimary ? 0.4 : 0.0),
                radius: package.isPrimary ? 20 : 0,
                x: 10,
                y: 10)
        .padding(.vertical)
    }
    
    var addonsText: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {
                ForEach(addons, id: \.self) { addon in
                    Text("• " + addon.title)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            packagePrice
        }
        .padding()
        .frame(width: 300)
        .background(Color.black)
    }
    
    var textAndPrice: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                packageText
                Spacer()
            }

            Text(package.description)
                .font(.subheadline)
                .lineSpacing(0)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
        }
        .padding()
    }
    
    var packageImage: some View {
        Image(package.image)
            .resizable()
            .scaledToFill()
            .frame(width: 300, height: package.isPrimary ? 380 : 150)
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
            .clipped()
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
            Text(package.discountedPrice, format: .euroNoDecimals)
                .font(.headline)
                .foregroundStyle(package.isPrimary ? .sixtOrange : .gray)
                .opacity(package.isPrimary ? 1 : 0)
            
            Text(package.originalPrice, format: .euroNoDecimals)
                .foregroundColor(Color(.systemGray4))
                .if(package.isPrimary, transform: {
                    $0.strikethrough()
                })
                
        }
    }
}

private extension FormatStyle where Self == FloatingPointFormatStyle<Double>.Currency {
    static var euroNoDecimals: Self {
        .currency(code: "EUR")
            .precision(.fractionLength(0))
    }
}
