//
//  WeatherAppApp.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import SwiftUI

@main
struct WeatherApp: App { 
    @StateObject var locationManager = LocationManager()
    
    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(locationManager)
        }
    }
}
