//
//  CityViewModel.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import Combine
import Resolver
import RealmSwift

/// Protocol that defines the requirements for a City ViewModel.
protocol CityViewModel: ObservableObject {
    /// A Boolean value indicating whether the city view should be shown.
    var showCity: Bool { get set }
    
    /// Searches for cities matching the provided name.
    /// - Parameter cityName: The name of the city to search for.
    func searchCity(cityName: String)
    
    /// A list of cities returned from the search.
    var cityList: [CityEntity] { get set }
    
    /// The currently selected city.
    var selectedCity: CityEntity? { get set }
    
    /// A Boolean value indicating whether the selected city exists in the local database.
    var isCityInLocalDatabase: Bool { get set }
    
    /// Saves the selected city to the local database.
    func saveCity()
    
    /// Fetches the list of cities from the local database.
    func fetchCities()
    
    /// Handles the event when a city cell is tapped.
    /// - Parameter city: The city that was tapped.
    func didTapCell(city: CityEntity)
    
    /// The current search text entered by the user.
    var searchText: String { get set }
    
    /// A Boolean value indicating whether an alert should be shown.
    var showAlert: Bool { get set }
    
    /// The title of the alert to be shown.
    var alertTitle: String { get set }
}

/// Default implementation of the `CityViewModel` protocol.
/// Manages searching, selecting, and saving cities, as well as handling city data from local storage.
class DefaultCityViewModel: CityViewModel {
    // MARK: - Published Properties
    
    /// A Boolean value indicating whether an alert should be shown.
    @Published var showAlert: Bool = false
    
    /// A Boolean value indicating whether the city view should be shown.
    @Published var showCity: Bool = false
    
    /// A list of cities returned from the search.
    @Published var cityList: [CityEntity] = []
    
    /// A Boolean value indicating whether the selected city exists in the local database.
    @Published var isCityInLocalDatabase: Bool = false
    
    /// The current search text entered by the user.
    @Published var searchText: String = ""
    
    /// The title of the alert to be shown.
    @Published var alertTitle: String = ""
    
    /// The currently selected city. Updates the local database status when set.
    @Published var selectedCity: CityEntity? {
        didSet {
            checkIfCityExistsInDatabase()
        }
    }
    
    /// The internet manager to check internet connectivity.
    @Published private var internetManager = InternetManager()
    
    // MARK: - Dependencies
    
    /// The weather repository to fetch data from the API.
    @Injected var weatherRepo: WeatherRepository
    
    // MARK: - Private Properties
    
    /// A set to store Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initializer
    
    /// Initializes a new instance of `DefaultCityViewModel`.
    init() {
        fetchCities()
    }
    
    // MARK: - Public Methods
    
    /// Handles the event when a city cell is tapped.
    /// Checks for internet connectivity before proceeding.
    /// - Parameter city: The city that was tapped.
    func didTapCell(city: CityEntity) {
        // Check internet connectivity
        guard internetManager.isConnected else {
            // Show alert if no internet connection
            alertTitle = "No internet available!"
            showAlert = true
            return
        }
        
        // Set the selected city and show the city view
        selectedCity = city
        showCity = true
    }
    
    /// Checks if the selected city exists in the local database.
    func checkIfCityExistsInDatabase() {
        guard let selectedCity = selectedCity else {
            isCityInLocalDatabase = false
            return
        }
        
        do {
            // Access the Realm database
            let realm = try Realm()
            let cityId = selectedCity.id
            // Check if the city exists in the database
            let existingCity = realm.object(ofType: RealmCityEntity.self, forPrimaryKey: cityId)
            isCityInLocalDatabase = existingCity != nil
        } catch {
            // Handle the error (e.g., logging or displaying an error message)
            print("Error accessing Realm database: \(error.localizedDescription)")
            isCityInLocalDatabase = false
        }
    }
    
    /// Searches for cities matching the provided name using the weather repository.
    /// - Parameter cityName: The name of the city to search for.
    func searchCity(cityName: String) {
        weatherRepo.findCity(name: cityName)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    // Log error if the search fails
                    Log.shared.printLog(error)
                }
            } receiveValue: { output in
                // Update the city list with the search results
                self.cityList = output
                Log.shared.printLog(output)
            }
            .store(in: &self.cancellables)
    }
    
    /// Saves the selected city to the local database if it doesn't already exist.
    func saveCity() {
        guard let selectedCity = selectedCity else { return }
        // Convert the CityEntity to a RealmCityEntity
        let realmCity = selectedCity.toRealmCityEntity()
        RealmManager.sharedInstance.asyncWrite { realm in
            // Check if the city already exists in the database
            if realm.object(ofType: RealmCityEntity.self, forPrimaryKey: realmCity.id) == nil {
                // If the city doesn't exist, add it to the database
                realm.add(realmCity)
            } else {
                // City already exists in the database
                Log.shared.printLog("City already exists: \(realmCity.name)")
            }
        } completion: {
            // Refresh the city list after saving
            self.fetchCities()
        }
    }
    
    /// Fetches the list of cities from the local database and updates the city list.
    func fetchCities() {
        // Fetch all RealmCityEntity objects from Realm
        let realmCities = RealmManager.sharedInstance.fetch(object: RealmCityEntity.self)
        
        // Convert each RealmCityEntity to CityEntity
        let cities = realmCities.map { realmCity -> CityEntity in
            return CityEntity(
                name: realmCity.name,
                lat: realmCity.lat,
                lon: realmCity.lon,
                localNames: realmCity.localNames
            )
        }
        
        // Update the city list and hide the city view
        self.cityList = Array(cities)
        self.showCity = false
    }
}
