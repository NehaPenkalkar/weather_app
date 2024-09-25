//
//  MockWeatherRepository.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Combine
import XCTest
@testable import WeatherApp

class MockWeatherRepository: WeatherRepository {
    
    var currentWeather: CurrentWeatherEntity?
    var forecast: ForecastEntity?
    var citiesToReturn: [CityEntity] = []
    var shouldReturnError = false
    
    func getCurrentWeather(coordinates: CoordinatesEntity) -> Publish<CurrentWeatherEntity> {
        if shouldReturnError {
            return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
        }
        if let weather = currentWeather {
            return Just(weather)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
        }
    }
    
    func getForecast(coordinates: CoordinatesEntity) -> Publish<ForecastEntity> {
        if shouldReturnError {
            return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
        }
        if let forecast = forecast {
            return Just(forecast)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
        }
    }
    
    func findCity(name: String) -> Publish<[CityEntity]> {
        if shouldReturnError {
            return Fail(error: NetworkError.genericError).eraseToAnyPublisher()
        } else {
            return Just(citiesToReturn)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
    }
}
