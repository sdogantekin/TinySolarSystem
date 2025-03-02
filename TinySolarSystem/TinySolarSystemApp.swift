//
//  TinySolarSystemApp.swift
//  TinySolarSystem
//
//  Created by Serkan Dogantekin on 2.03.2025.
//

import SwiftUI

@main
struct TinySolarSystemApp: App {
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some Scene {
        WindowGroup {
            if networkMonitor.isConnected {
                SplashScreen()
            } else {
                ErrorScreen(errorType: .offline) {
                    // This is a dummy action since we can't force network reconnection
                    // The NetworkMonitor will automatically update when connection is restored
                }
            }
        }
        .environmentObject(networkMonitor)
    }
}
