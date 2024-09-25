//
//  LocationManager.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import CoreLocation

/// A final class that manages location updates using Core Location.
/// Conforms to `NSObject` and `ObservableObject` for integration with SwiftUI.
final class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    /// The current authorization status for location services.
    @Published private(set) var authorizationStatus: CLAuthorizationStatus?
    
    /// The most recent location received from the location manager.
    @Published private(set) var location: CLLocation?
    
    // MARK: - Private Properties
    
    /// The underlying `CLLocationManager` used to obtain location updates.
    private let locationManager: CLLocationManager
    
    // MARK: - Initializer
    
    /// Initializes a new instance of `LocationManager` and sets up the `CLLocationManager`.
    override init() {
        locationManager = CLLocationManager()
        super.init()
        // Set the delegate to receive location updates and authorization changes.
        locationManager.delegate = self
        // Set the distance filter to update location only when the device moves 100 meters.
        locationManager.distanceFilter = 100
    }
    
    // MARK: - Public Methods
    
    /// Starts the location services by requesting authorization and starting updates.
    func start() {
        // Request permission to access location when the app is in use.
        locationManager.requestWhenInUseAuthorization()
        // Begin receiving location updates.
        locationManager.startUpdatingLocation()
    }
}

// MARK: - CLLocationManagerDelegate

/// Extension to conform to `CLLocationManagerDelegate` and handle location updates and authorization changes.
extension LocationManager: CLLocationManagerDelegate {
    
    /// Called when the authorization status changes.
    /// - Parameter manager: The location manager reporting the change.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Update the published authorization status.
        authorizationStatus = manager.authorizationStatus
    }
    
    /// Called when new location data is available.
    /// - Parameters:
    ///   - manager: The location manager that generated the update event.
    ///   - locations: An array of `CLLocation` objects representing the updated locations.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Get the last location from the array and update the published location.
        guard let location = locations.last else { return }
        self.location = location
    }
}
