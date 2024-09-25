//
//  RequestBuilder.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import WebKit

/// A protocol defining methods for building URL requests.
/// It includes methods to construct the request and its parameters.
public protocol RequestBuilder {
    /// Builds a `URLRequest` for the given `APIService` target.
    /// - Parameter target: The `APIService` target containing endpoint information.
    /// - Returns: An optional `URLRequest` if the request could be built successfully.
    func buildRequest(target: APIService) -> URLRequest?
    
    /// Builds the parameters for a given `Task`.
    /// - Parameter task: The `Task` containing parameter information.
    /// - Returns: An `ApiParameters` object with the constructed parameters.
    func buildParams(task: Task) -> ApiParameters
}

public extension RequestBuilder {
    /// Builds a `URLRequest` for the given `APIService` target.
    /// - Parameter target: The `APIService` target containing endpoint information.
    /// - Returns: An optional `URLRequest` if the request could be built successfully.
    func buildRequest(target: APIService) -> URLRequest? {
        // The URLRequest that will be returned
        var request: URLRequest
        
        // Get the HTTP method and parameters from the target
        let method = target.method.value
        let data = buildParams(task: target.task)
        
        // Construct the URL string and remove any unwanted characters
        let urlString = "\(target.baseURL + target.endPoint)".replacingOccurrences(of: "amp;", with: "")
        guard var url = URL(string: urlString) else {
            return nil
        }
        
        // Add query parameters to the URL
        if let urlParams = data.queryParameters {
            for (key, value) in urlParams {
                url = url.appending(key, value: "\(value)")
            }
        }
        
        // Final URL that will be used for the API call
        request = URLRequest(url: url)
        
        // Set the HTTP method (e.g., GET, POST)
        request.httpMethod = method
        
        // Set the User-Agent header
        DispatchQueue.main.async {
            if let agent = WKWebView().value(forKey: "userAgent") as? String {
                request.setValue(agent, forHTTPHeaderField: "User-Agent")
            }
        }
        
        // If the method is not GET and there are body parameters, add them to the request body
        if let body = data.parameters, target.method != .get {
            switch data.encoding {
            case .urlEncoding:
                var requestedBodyComponents = URLComponents()
                var queryItems = [URLQueryItem]()
                
                for (key, value) in body {
                    let queryItem = URLQueryItem(
                        name: key,
                        value: String(describing: value).addingPercentEncodingForURLQueryValue()
                    )
                    queryItems.append(queryItem)
                }
                
                requestedBodyComponents.queryItems = queryItems
                request.httpBody = requestedBodyComponents.query?.data(using: .utf8)
                
            case .jsonEncoding:
                let jsonData = try? JSONSerialization.data(withJSONObject: body)
                request.httpBody = jsonData
                
            default:
                break
            }
        }
        
        // Log the request details for debugging
        printRequest(request: request, target: target)
        return request
    }
    
    /// Builds the parameters for a given `Task`.
    /// - Parameter task: The `Task` containing parameter information.
    /// - Returns: An `ApiParameters` object with the constructed parameters.
    func buildParams(task: Task) -> ApiParameters {
        switch task {
        case .requestPlain:
            return ApiParameters(parameters: [:])
            
        case .requestParameters(parameters: let parameters, queryParameters: let urlParameters, encoding: let encoding):
            return ApiParameters(parameters: parameters, queryParameters: urlParameters, encoding: encoding)
        }
    }
    
    /// Prints the details of the `URLRequest` for debugging purposes.
    /// - Parameters:
    ///   - request: The `URLRequest` to be printed.
    ///   - target: The `APIService` target containing endpoint information.
    func printRequest(request: URLRequest, target: APIService) {
        Log.shared.printLog("""
        API: \(target.baseURL + target.endPoint)
        HTTP Method: \(String(describing: request.httpMethod))
        Headers: \(request.allHTTPHeaderFields ?? [:])
        RequestedURL: \(String(describing: request.url))
        Parameters: \(String(describing: buildParams(task: target.task).parameters))
        """)
    }
}

private extension URL {
    /// Appends a query item to the URL.
    /// - Parameters:
    ///   - queryItem: The name of the query item.
    ///   - value: The value of the query item.
    /// - Returns: A new `URL` with the query item appended.
    func appending(_ queryItem: String, value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }
        
        // Create an array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        
        // Create the new query item
        let queryItem = URLQueryItem(name: queryItem, value: value)
        
        // Append the new query item to the existing query items array
        queryItems.append(queryItem)
        
        // Update the URL components with the new query items
        urlComponents.queryItems = queryItems
        
        // Return the new URL with the appended query item
        return urlComponents.url!
    }
}

private extension String {
    /// Returns a new string by adding percent encoding to the query value.
    /// This is necessary for properly encoding special characters in URLs.
    func addingPercentEncodingForURLQueryValue() -> String? {
        let allowedCharacters = CharacterSet.urlQueryValueAllowed()
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}

private extension CharacterSet {
    /// Returns the character set for characters allowed in URL query values.
    ///
    /// The query component of a URL is the component immediately following a question mark (?).
    /// According to RFC 3986, the set of unreserved characters includes:
    ///
    /// `ALPHA / DIGIT / "-" / "." / "_" / "~" / "/" / "?"`
    ///
    /// This character set is used to percent-encode query values in URLs.
    static func urlQueryValueAllowed() -> CharacterSet {
        return CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~/?")
    }
}
