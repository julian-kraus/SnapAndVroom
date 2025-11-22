//
//  ConfirmationView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI

struct ConfirmationView: View {
    @EnvironmentObject private var navigation: Navigation
    
    var body: some View {
        VStack {
            Text("Confirmation View")
            backButton
            goToRoot
        }
    }
    
    var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            Text("Previous")
        }
    }
    
    var goToRoot: some View {
        Button {
            navigation.goToRoot()
        } label: {
            Text("Go to root")
        }
    }
}
