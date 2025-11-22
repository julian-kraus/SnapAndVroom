//
//  PackagesView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//
import SwiftUI

struct PackagesView: View {
    @EnvironmentObject private var navigation: Navigation
    
    var body: some View {
        VStack {
            Text("Packages View")
            nextButton
            backButton
        }
    }
    
    var backButton: some View {
        Button {
            navigation.goBack()
        } label: {
            Text("Previous")
        }
    }
    
    var nextButton: some View {
        Button {
            navigation.goTo(view: .addons)
        } label: {
            Text("Next")
        }
    }
}
