//
//  Snap_VroomApp.swift
//  Snap&Vroom
//
//  Created by Julian Kraus on 21.11.25.
//

import SwiftUI
import SwiftData

@main
struct Snap_VroomApp: App {
    @ObservedObject private var navigation = Navigation()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $navigation.navPath) {
                PickupView()
                    .navigationBarBackButtonHidden(true)
                    .navigationDestination(for: Navigation.View.self) { view in
                        switch view {
                        case .pickup:
                            PickupView()
                        case .camera:
                            CameraView()
                        case .packages:
                            PackagesView()
                        case .addons:
                            AddonsView()
                        case .car:
                            CarView()
                        case .insurance:
                            InsuranceView()
                        case .confirmation:
                            ConfirmationView()
                        }
                    }
            }
            .environmentObject(navigation)
        }
        .modelContainer(sharedModelContainer)
    }
}
