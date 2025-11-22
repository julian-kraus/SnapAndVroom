//
//  PickupView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI

struct PickupView: View {
    @EnvironmentObject private var navigation: Navigation
    @EnvironmentObject private var pickupViewModel: PickupViewModel
    
    var body: some View {
        ZStack {
            Color(.sixtOrange)
                .ignoresSafeArea()

            VStack {
                Text("Pickup View")
                nextButton
                backButton
            }
        }.task {
            await pickupViewModel.initializeBooking()
        }
    }
    
    var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            
        }
    }
    
    var nextButton: some View {
        Button {
            navigation.goTo(view: .camera)
        } label: {
            Text("Next")
        }
    }
}
