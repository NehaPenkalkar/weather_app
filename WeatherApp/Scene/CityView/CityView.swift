//
//  CityView.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import SwiftUI

struct CityView<VM: CityViewModel>: View {
    @StateObject var viewModel: VM
    
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.cityList) { city in
                            Text(city.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding()
                                .frame(maxWidth: proxy.size.width, alignment: .leading)
                                .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 10.0))
                                .padding(.horizontal)
                                .onTapGesture {
                                    viewModel.didTapCell(city: city)
                                }
                        }
                    }
                }
                .frame(maxWidth: proxy.size.width, alignment: .leading)
                .refreshable {
                    viewModel.fetchCities()
                }
            }
            .navigationTitle("Add City")
            .searchable(text: $viewModel.searchText, prompt: "Search for a city")
            .onChange(of: viewModel.searchText) { cityName in
                viewModel.searchCity(cityName: cityName)
            }
            .fullScreenCover(isPresented: $viewModel.showCity) {
                VStack {
                    navBarView()
                    WeatherView(viewModel: DefaultWeatherViewModel(cityName: viewModel.selectedCity?.name,
                                                                   coordinates: CoordinatesEntity(lat: viewModel.selectedCity?.lat,
                                                                                                  lon: viewModel.selectedCity?.lon)))
                }
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("No internet available!"),
                      message: nil,
                      dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func navBarView() -> some View {
        HStack {
            Button("Cancel") {
                viewModel.showCity = false
            }
            .padding(.leading)
            
            Spacer()
            
            if !viewModel.isCityInLocalDatabase {
                Button("Add") {
                    viewModel.saveCity()
                    viewModel.showCity = false
                }
                .padding(.trailing)
            }
        }
    }
}
