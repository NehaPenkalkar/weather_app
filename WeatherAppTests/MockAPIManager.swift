//
//  MockAPIManager 2.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Combine
import XCTest
@testable import WeatherApp

class MockAPIManager: APIManagerProtocol {
    
    var shouldReturnError = false
    var currentWeatherResponse: CurrentWeatherEntity?
    var forecastResponse: ForecastEntity?
    var cityResponse: [CityEntity]?
    
    func performRequest<T>(target: APIService, responseModel: T.Type) -> Publish<T> where T: Decodable {
        if shouldReturnError {
            return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
        }
        
        if let weather = currentWeatherResponse as? T {
            return Just(weather)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        if let forecast = forecastResponse as? T {
            return Just(forecast)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        if let city = cityResponse as? T {
            return Just(city)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
    }
}
