//
//  AddonsView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI

enum AddonType { case toggle, stepper }

struct Addon: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let priceText: String
    let price: Double
    let iconName: String
    let details: String
    let type: AddonType
    var maxQuantity: Int = 5

    var isSelected: Bool = false
    var isExpanded: Bool = false
    var quantity: Int = 0
}

struct AddonsView: View {
    @EnvironmentObject private var navigation: Navigation

    @State private var addons: [Addon] = [

        Addon(
            title: "Additional driver",
            subtitle: "Share the driving and stay relaxed.",
            priceText: "11.00 € / day & driver",
            price: 11.0,
            iconName: "person.2.fill",
            details: """
    • Switch drivers during the trip for a more relaxed and safer journey.
    • Every additional driver must present a valid driver’s license at pickup.
    """,
            type: .stepper,
            maxQuantity: 8
        ),

        Addon(
            title: "Navigation & smartphone integration",
            subtitle: "Built-in navigation, Android Auto & CarPlay.",
            priceText: "11.00 € / day",
            price: 11.0,
            iconName: "map.fill",
            details: """
    • The vehicle includes a navigation system for reliable and on-time arrival.
    • Use Android Auto or Apple CarPlay via the car’s touchscreen.
    • Make calls or play music directly through your connected smartphone.
    """,
            type: .toggle
        ),

        Addon(
            title: "Fuel & charging service",
            subtitle: "Return the car without refuelling.",
            priceText: "24.99 € one-time",
            price: 24.99,
            iconName: "fuelpump.fill",
            details: """
    • Save time during return — no refuelling or charging required.
    • SIXT refuels or charges the vehicle for you after the rental.
    • Fuel or electricity is billed according to current daily market prices.
    """,
            type: .toggle
        ),

        Addon(
            title: "Baby seat",
            subtitle: "For babies and toddlers up to 4 years.",
            priceText: "13.50 € / day",
            price: 13.50,
            iconName: "carseat.left.fill",
            details: """
    • Suitable for babies and toddlers up to 4 years (40–105 cm).
    • Must be installed rear-facing for safety.
    """,
            type: .stepper,
            maxQuantity: 8
        ),

        Addon(
            title: "Child seat",
            subtitle: "For children from 15 months to 12 years.",
            priceText: "13.50 € / day",
            price: 13.50,
            iconName: "carseat.left.fill",
            details: """
    • Suitable for children aged 15 months to 12 years (76–150 cm).
    """,
            type: .stepper,
            maxQuantity: 8
        ),

        Addon(
            title: "Booster seat",
            subtitle: "For children from 8 to 12 years.",
            priceText: "12.50 € / day",
            price: 12.50,
            iconName: "carseat.left.fill",
            details: """
    • Suitable for children aged 8 to 12 years (135–150 cm).
    """,
            type: .stepper,
            maxQuantity: 8
        )
    ]

    private var totalPrice: Double {
        addons.reduce(0) { sum, addon in
            switch addon.type {
            case .toggle:
                return sum + (addon.isSelected ? addon.price : 0)
            case .stepper:
                return sum + Double(addon.quantity) * addon.price
            }
        }
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(addons.indices, id: \.self) { index in
                            AddonTile(addon: $addons[index])
                                .padding(.horizontal)
                        }

                        Spacer(minLength: 16)
                    }
                    .padding(.top, 24)
                }

                bottomBar
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    navigation.goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                        .padding(.trailing, 4)
                }

                Spacer()

                Text("Which extras do you need?")
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)

                Spacer()

                Color.clear.frame(width: 26, height: 26)
            }
            .padding(.horizontal)
            .padding(.top, 12)

        }
        .background(Color(.systemBackground))
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(.headline)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.2f €", totalPrice))
                        .font(.headline)
                }
            }
            .padding(.horizontal)

            Button {
                navigation.goTo(view: .car)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("sixtOrange"))
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground).ignoresSafeArea(edges: .bottom))
    }
}

struct AddonTile: View {
    @Binding var addon: Addon

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                // Top row: icon, title, control (toggle/stepper)
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: addon.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(Color("sixtOrange"))
                        .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(addon.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(addon.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()

                    // Control on the right
                    if addon.type == .stepper {
                        StepperPill(quantity: $addon.quantity, max: addon.maxQuantity)
                            .onChange(of: addon.quantity) { oldValue, newValue in
                                addon.isSelected = newValue > 0
                            }
                    } else {
                        Toggle("", isOn: Binding(
                            get: { addon.isSelected },
                            set: { addon.isSelected = $0 }
                        ))
                        .labelsHidden()
                    }
                }

                // Price inside tile
                Text(addon.priceText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                // Details button row
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        addon.isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(addon.isExpanded ? "Hide details" : "Show details")
                            .font(.subheadline.weight(.semibold))
                            .underline()
                        Spacer()
                        Image(systemName: addon.isExpanded ? "chevron.up" : "chevron.down")
                    }
                    .foregroundColor(.primary)
                }
                .buttonStyle(.plain)

                // Expanded description
                if addon.isExpanded {
                    Text(addon.details)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray5))
                        )
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color("sixtOrange"), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(UIColor.systemBackground))
                )
        )
    }
}

struct StepperPill: View {
    @Binding var quantity: Int
    var max: Int

    var body: some View {
        HStack(spacing: 0) {
            Button {
                if quantity > 0 { quantity -= 1 }
            } label: {
                Image(systemName: "minus")
                    .frame(width: 22, height: 22)
            }

            Text("\(quantity)")
                .frame(width: 30)
                .font(.headline)
                .foregroundColor(.primary)

            Button {
                if quantity < max { quantity += 1 }
            } label: {
                Image(systemName: "plus")
                    .frame(width: 22, height: 22)
            }
        }
        .padding(6)
        .background(Color(.systemBackground))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
        .foregroundColor(.primary)
    }
}

struct AddonsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AddonsView()
                .environmentObject(Navigation())
        }
    }
}

