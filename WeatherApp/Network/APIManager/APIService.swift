//
//  WeatherAPI.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation

/// A typealias for a dictionary with `String` keys and `Any` values.
/// Used for representing JSON-like data structures.
public typealias AnyDict = [String: Any]

/// An enumeration representing different API services provided by the application.
/// Each case corresponds to a specific API endpoint.
public enum APIService {
    /// Fetches the current weather data for the given coordinates.
    case currentWeather(coordinates: CoordinatesEntity)
    
    /// Fetches the weather forecast data for the given coordinates.
    case forecast(coordinates: CoordinatesEntity)
    
    /// Searches for a city by name.
    case find(name: String)
}

extension APIService {
    /// The base URL for the OpenWeatherMap API.
    var baseURL: String {
        return "https://api.openweathermap.org"
    }
    
    /// The specific endpoint path for each API service.
    var endPoint: String {
        switch self {
        case .currentWeather:
            return "/data/2.5/weather"
        case .forecast:
            return "/data/2.5/forecast"
        case .find:
            return "/geo/1.0/direct"
        }
    }
    
    /// The HTTP method used for the request.
    var method: HTTPMethod {
        return .get
    }
    
    /// The task that defines the parameters and encoding for the request.
    var task: Task {
        // Common parameters for all API requests.
        guard let key = Bundle.main.infoDictionary?["API_KEY"] as? String else {
            return .requestPlain
        }
        
        var params = [
            "appid": key,
            "lang": Locale.current.language.languageCode?.identifier ?? "en",
            "units": "metric"
        ]
        
        // Additional parameters based on the specific API service.
        switch self {
        case .currentWeather(let coordinates), .forecast(let coordinates):
            params["lat"] = coordinates.lat?.description
            params["lon"] = coordinates.lon?.description
        case .find(let name):
            params["q"] = name
            params["limit"] = "0"
        }
        
        // Returns the task with the parameters and URL encoding.
        return .requestParameters(
            parameters: .none,
            queryParameters: params,
            encoding: .urlEncoding
        )
    }
}

/// An enumeration representing different types of network tasks for API requests.
public enum Task {
    /// A request with no additional data.
    case requestPlain
    
    /// A request that includes parameters and query parameters with a specified encoding.
    case requestParameters(
        parameters: AnyDict? = nil,
        queryParameters: [String: String]? = nil,
        encoding: ParameterEncoding = .none
    )
}

/// An enumeration representing HTTP methods used in network requests.
public enum HTTPMethod {
    /// HTTP GET method.
    case get
    /// HTTP POST method.
    case post
    
    /// The string representation of the HTTP method.
    var value: String {
        switch self {
        case .get:
            return "GET"
        case .post:
            return "POST"
        }
    }
}

/// An enumeration representing parameter encoding strategies for network requests.
public enum ParameterEncoding {
    /// Parameters are encoded as JSON in the request body.
    case jsonEncoding
    /// Parameters are encoded as URL query parameters.
    case urlEncoding
    /// No parameter encoding.
    case none
}
