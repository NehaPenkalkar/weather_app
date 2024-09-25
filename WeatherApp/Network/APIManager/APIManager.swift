//
//  ApiService.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import UIKit
import Combine
import CommonCrypto

public protocol APIManagerProtocol {
    func performRequest<T: Decodable>(target: APIService, responseModel: T.Type) -> Publish<T>
}

/// A typealias for a generic `AnyPublisher` that publishes values of type `T` conforming to `Codable`, and may produce an `Error`.
public typealias Publish<T: Codable> = AnyPublisher<T, Error>

/// A manager class responsible for performing REST API calls.
/// Conforms to `NSObject` and `RequestBuilder`.
public class APIManager: NSObject, RequestBuilder, APIManagerProtocol {
    /// A shared singleton instance of `APIManager`.
    static let shared = APIManager()
    
    /// The URL session used for network requests.
    var session: URLSession
    
    /// The configuration for the URL session.
    let config = URLSessionConfiguration.default
    
    /// Private initializer to prevent external instantiation.
    private override init() {
        session = URLSession(configuration: config)
    }
    
    /// Performs a network request and decodes the response into the specified model.
    ///
    /// - Parameters:
    ///   - target: The API service target defining the request parameters.
    ///   - responseModel: The type of the model to decode from the response.
    /// - Returns: A publisher that emits the decoded model or an error.
    public func performRequest<T: Decodable>(target: APIService,
                                             responseModel: T.Type) -> Publish<T> {
        
        // Build the URLRequest using the provided target.
        guard let request = buildRequest(target: target) else {
            // Return a failed publisher if the request could not be built.
            return Fail(error: NetworkError.invalidRequest)
                .eraseToAnyPublisher()
        }
        
        // Perform the network request using a data task publisher.
        return session.dataTaskPublisher(for: request)
            .receive(on: DispatchQueue.main)
            .mapError { $0 } // Map any errors to the publisher's error type.
            .tryMap { data, response in
                // Ensure the response is an HTTPURLResponse.
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.noResponse
                }
                
                let statusCode = httpResponse.statusCode
                
                /// If status code is between 200 and 299 (success), then return the data.
                guard statusCode >= 200, statusCode <= 299 else {
                    throw NetworkError.genericError
                }
                
                // Log the response data for debugging purposes.
                Log.shared.printLog(data.prettyPrint)
                return data
            }
            // Decode the data into the specified model type.
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

/// A struct representing API parameters used in network requests.
public struct ApiParameters {
    /// The parameters to be included in the request body.
    var parameters: AnyDict?
    
    /// The query parameters to be appended to the URL.
    var queryParameters: [String: String]?
    
    /// The encoding strategy for the parameters.
    var encoding: ParameterEncoding?
}

// MARK: - Network Errors

/// An enumeration of network-related errors.
/// Conforms to `Error`, `CaseIterable`, and `LocalizedError`.
public enum NetworkError: String, Error, CaseIterable, LocalizedError {
    case genericError
    case noStatusCode
    case invalidRequest
    case noResponse
    case invalidURL
    case noInternet
    case objectCannotBeConverted
    
    /// A localized description of the failure reason.
    public var failureReason: String? {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
