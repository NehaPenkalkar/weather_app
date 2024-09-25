//
//  WeatherViewModelTests.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Combine
import XCTest
@testable import WeatherApp

class WeatherViewModelTests: XCTestCase {
    
    var viewModel: DefaultWeatherViewModel!
    var mockWeatherRepo: MockWeatherRepository!
    
    override func setUp() {
        super.setUp()
        
        // Manually inject the mock repository into the view model
        mockWeatherRepo = MockWeatherRepository()
        
        // Create a view model instance and inject the mock repository
        viewModel = DefaultWeatherViewModel()
        viewModel.weatherRepo = mockWeatherRepo // Override the @Injected property manually
    }
    
    override func tearDown() {
        viewModel = nil
        mockWeatherRepo = nil
        super.tearDown()
    }
    
    func testGetWeather() {
        // Mock the repository response
        let expectedWeather = CurrentWeatherEntity(name: "Test City", coord: CoordinatesEntity(lat: 10.0, lon: 20.0))
        mockWeatherRepo.currentWeather = expectedWeather
        
        viewModel.getWeather()
        
        XCTAssertNotNil(viewModel.currentWeather)
        XCTAssertEqual(viewModel.currentWeather?.name, "Test City")
    }
    
    func testMetersPerSecondToKilometersPerHour() {
        let speedInMetersPerSecond = 10.0
        let speedInKmPerHour = viewModel.metersPerSecondToKilometersPerHour(speed: speedInMetersPerSecond)
        
        XCTAssertEqual(speedInKmPerHour, "36.00")
    }
}
