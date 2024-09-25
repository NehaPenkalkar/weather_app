//
//  WeatherRepository.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import Combine

public protocol WeatherRepository {
    func getCurrentWeather(coordinates: CoordinatesEntity) -> Publish<CurrentWeatherEntity>
    func getForecast(coordinates: CoordinatesEntity) -> Publish<ForecastEntity>
    func findCity(name: String) -> Publish<[CityEntity]>
}

final class DefaultWeatherRepository: WeatherRepository {
    
    private var networkManager: APIManagerProtocol
      
      // Initialize with a default value for `networkManager`
      init(networkManager: APIManagerProtocol = APIManager.shared) {
          self.networkManager = networkManager
      }
    
    private lazy var decoder: JSONDecoder = {
        var decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
    
    func getCurrentWeather(coordinates: CoordinatesEntity) -> Publish<CurrentWeatherEntity> {
        networkManager.performRequest(target: .currentWeather(coordinates: coordinates), responseModel: CurrentWeatherEntity.self)
            .receive(on: DispatchQueue.main)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func getForecast(coordinates: CoordinatesEntity) -> Publish<ForecastEntity> {
        networkManager.performRequest(target: .forecast(coordinates: coordinates), responseModel: ForecastEntity.self)
            .receive(on: DispatchQueue.main)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
    
    func findCity(name: String) -> Publish<[CityEntity]> {
        networkManager.performRequest(target: .find(name: name), responseModel: [CityEntity].self)
            .receive(on: DispatchQueue.main)
            .mapError { $0 }
            .eraseToAnyPublisher()
    }
}
