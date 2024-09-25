//
//  WeatherView.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import SwiftUI
import CoreLocation

struct WeatherView<VM: WeatherViewModel>: View {
    @StateObject var viewModel: VM
    @EnvironmentObject var locationManager: LocationManager
    @State var isPresented: Bool = false
    
    var body: some View {
        content
            .navigationBarHidden(true)
            .onAppear {
                viewModel.getWeather()
            }
            .onReceive(locationManager.$location) { _ in
                guard let coordinates = viewModel.locationManager.location?.coordinate else { return }
                viewModel.coordinates = CoordinatesEntity(lat: coordinates.latitude, lon: coordinates.longitude)
                viewModel.getWeather()
            }
    }
    
    @ViewBuilder private var content: some View {
        if viewModel.isAPILoading {
            ProgressView()
                .frame(width: 100, height: 50)
        } else {
            ScrollView {
                VStack(spacing: 8) {
                    currentWeatherView(currentWeather: viewModel.currentWeather)
                    
                    weatherInfoView(currentWeather: viewModel.currentWeather)
                        .padding()
                        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10.0))
                        .padding()
                    
                    VStack(alignment: .leading) {
                        if viewModel.dailyForecast.isEmpty {
                            Text("5-DAY FORECAST")
                                .font(.caption2)
                                .padding(.bottom, 8)
                        }
                        
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(viewModel.dailyForecast, id: \.self) { day in
                                Divider()
                                fiveDayForecast(day: day)
                                    .onTapGesture {
                                        viewModel.selectedWeather = day
                                        isPresented = true
                                    }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10.0))
                    .padding()
                }
            }
            .sheet(isPresented: $isPresented) {
                weatherInfoView(forecast: viewModel.selectedWeather)
                    .presentationDetents([.custom(FromDetent.self), .custom(ToDetent.self)])
            }
        }
    }
    
    struct FromDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            return 100
        }
    }
    
    struct ToDetent: CustomPresentationDetent {
        static func height(in context: Context) -> CGFloat? {
            return 200
        }
    }
    
    private func weatherInfoView(currentWeather: CurrentWeatherEntity?) -> some View {
        infoView(temperature: currentWeather?.main?.temp, humidity: currentWeather?.main?.humidity, windSpeed: currentWeather?.wind?.speed)
    }
    
    private func weatherInfoView(forecast: DailyForecast?) -> some View {
        infoView(temperature: forecast?.temp, humidity: forecast?.humidity, windSpeed: forecast?.windSpeed)
    }
    
    private func infoView(temperature: Double?, humidity: Int?, windSpeed: Double?) -> some View {
        HStack {
            VStack {
                Text("Temperature")
                Text("\(temperature ?? 0, specifier: "%.1f") °")
            }
            .frame(maxWidth: .infinity) // Make each VStack take equal width
            
            VStack {
                Text("Humidity")
                Text("\(humidity ?? 0)%")
            }
            .frame(maxWidth: .infinity) // Make each VStack take equal width
            
            VStack {
                Text("Wind Speed")
                Text("\(viewModel.metersPerSecondToKilometersPerHour(speed: windSpeed ?? 0)) km/h")
            }
            .frame(maxWidth: .infinity) // Make each VStack take equal width
        }
    }
    
    private func currentWeatherView(currentWeather: CurrentWeatherEntity?) -> some View {
        HStack {
            Spacer()
            VStack(alignment: .center, spacing: 4) {
                Text(currentWeather?.name ?? "--")
                    .font(.title)
                Text(currentWeather?.main?.temp?.toString ?? "--")
                    .font(.system(size: 60))
                Image(systemName: currentWeather?.weather?.first?.main?.imageName ?? "")
                    .font(.system(size: 42))
                Text(currentWeather?.weather?.first?.description ?? "")
            }
            Spacer()
        }
        .padding()
    }
    
    private func fiveDayForecast(day: DailyForecast) -> some View {
        HStack {
            Text(day.day.capitalized)
                .frame(width: 50, alignment: .leading)
                .lineLimit(1)
            
            Spacer()
            
            VStack {
                Image(day.descEntity?.main?.imageName ?? "")
                    .resizable()
                    .frame(width: 20, height: 20)
                
                Text("(\(day.descEntity?.description ?? ""))".capitalized)
                    .font(.caption2)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(day.minTemp.toString)
                    .multilineTextAlignment(.trailing)
                
                Text("—")
                Text(day.maxTemp.toString)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}
