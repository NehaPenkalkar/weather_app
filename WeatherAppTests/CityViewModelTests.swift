//
//  DefaultCityViewModelTests.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import XCTest
import Combine
import RealmSwift
@testable import WeatherApp

class DefaultCityViewModelTests: XCTestCase {
    
    var viewModel: DefaultCityViewModel!
    var mockWeatherRepo: MockWeatherRepository!
    
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        super.setUp()
        
        // Initialize mocks
        mockWeatherRepo = MockWeatherRepository()
        
        // Create a view model instance and inject the mock repository
        viewModel = DefaultCityViewModel()
        viewModel.weatherRepo = mockWeatherRepo // Override the @Injected property manually

    }
    
    override func tearDown() {
        viewModel = nil
        mockWeatherRepo = nil
        super.tearDown()
    }
    
    func testDidTapCellWithInternet() {
        
        let city = CityEntity(name: "Tapped City", lat: 30.0, lon: 50.0, localNames: nil)
        
        viewModel.didTapCell(city: city)
        
        // Assert: Verify that the selected city is updated and the city view is shown
        XCTAssertEqual(viewModel.selectedCity?.name, "Tapped City")
        XCTAssertTrue(viewModel.showCity)
    }
    
    func testSearchCity() {
        // Arrange: Mock the repository to return a list of cities
        let mockCities = [
            CityEntity(name: "City 1", lat: 10.0, lon: 20.0, localNames: nil),
            CityEntity(name: "City 2", lat: 15.0, lon: 25.0, localNames: nil)
        ]
        mockWeatherRepo.citiesToReturn = mockCities
        
        let expectation = self.expectation(description: "Search City")
        
        // Act: Perform city search
        viewModel.searchCity(cityName: "Test")
        
        // Assert: Verify that the city list is updated with the mock results
        viewModel.$cityList
            .sink { cities in
                XCTAssertEqual(cities.count, 2)
                XCTAssertEqual(cities.first?.name, "City 1")
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
