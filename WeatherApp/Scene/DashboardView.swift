//
//  DashboardView.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import SwiftUI

struct DashboardView: View { 
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        TabView {
            Group {
                WeatherView(viewModel: DefaultWeatherViewModel())
                    .tabItem {
                        Label("Weather", systemImage: "thermometer.sun.fill")
                    }
                
                CityView(viewModel: DefaultCityViewModel())
                    .tabItem {
                        Label("Cities", systemImage: "list.star")
                    }
            }
            .onAppear {
                locationManager.start()
            }
        }
    }
}
