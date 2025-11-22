//
//  InsuranceView.swift
//  Snap&Vroom
//
//  Created by Neli Shahapuni on 11/22/25.
//

import SwiftUI

struct InsuranceView: View {
    @EnvironmentObject private var navigation: Navigation
    
    var body: some View {
        VStack {
            Text("Insurance View")
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
            navigation.goTo(view: .confirmation)
        } label: {
            Text("Next")
        }
    }
}
