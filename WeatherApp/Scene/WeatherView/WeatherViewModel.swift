//
//  WeatherViewModel.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import Combine
import Resolver
import RealmSwift
import CoreLocation

/// Protocol that defines the requirements for a Weather ViewModel.
protocol WeatherViewModel: ObservableObject {
    /// Fetches the current weather and forecast data.
    func getWeather()
    
    /// The current weather data.
    var currentWeather: CurrentWeatherEntity? { get set }
    
    /// The daily forecast data.
    var dailyForecast: [DailyForecast] { get set }
    
    /// The location manager to obtain the user's location.
    var locationManager: LocationManager { get set }
    
    /// The coordinates for which to fetch weather data.
    var coordinates: CoordinatesEntity? { get set }
    
    /// A flag indicating whether an API request is in progress.
    var isAPILoading: Bool { get set }
    
    func metersPerSecondToKilometersPerHour(speed: Double) -> String
    
    var selectedWeather: DailyForecast? { get set }
}

/// Default implementation of the `WeatherViewModel` protocol.
/// Manages fetching weather data from an API, caching it, and providing it to the view.
class DefaultWeatherViewModel: WeatherViewModel {
    // MARK: - Published Properties

    /// The daily forecast data, published to update the view when changed.
    @Published var dailyForecast: [DailyForecast] = []
    
    /// The location manager to obtain the user's location.
    @Published var locationManager = LocationManager()
    
    /// The current weather data, published to update the view when changed.
    @Published var currentWeather: CurrentWeatherEntity?
    
    /// The coordinates for which to fetch weather data.
    @Published var coordinates: CoordinatesEntity?
    
    /// The internet manager to check internet connectivity.
    @Published var internetManager = InternetManager()
    
    /// A flag indicating whether an API request is in progress.
    @Published var isAPILoading: Bool = false
    
    @Published var selectedWeather: DailyForecast?

    // MARK: - Dependencies

    /// The weather repository to fetch data from the API.
    @Injected var weatherRepo: WeatherRepository
    
    // MARK: - Private Properties

    /// A set to store Combine cancellables.
    private var cancellables = Set<AnyCancellable>()
    
    /// The city name, if provided.
    private var cityName: String?
    
    // MARK: - Initializer

    /// Initializes a new instance of `DefaultWeatherViewModel`.
    ///
    /// - Parameters:
    ///   - cityName: An optional city name to fetch weather data for a specific city.
    ///   - coordinates: Optional coordinates to fetch weather data for a specific location.
    init(cityName: String? = nil, coordinates: CoordinatesEntity? = nil) {
        self.cityName = cityName
        
        // Check if coordinates were passed in via initializer
        if let coordinates = coordinates {
            self.coordinates = coordinates
        } else {
            // Attempt to load cached coordinates
            if let cachedCoordinates = loadCurrentWeatherFromCache()?.coord {
                self.coordinates = cachedCoordinates
                return
            }
            
            // Start location updates if no coordinates are available
            if locationManager.location == nil {
                locationManager.start()
            }
            
            // Subscribe to location updates
            locationManager.$location
                .sink { [weak self] location in
                    guard let location = location else { return }
                    
                    // Update coordinates when a new location is available
                    self?.coordinates = CoordinatesEntity(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - Public Methods

    /// Fetches the current weather and forecast data.
    func getWeather() {
        // Check internet connectivity
        guard internetManager.isConnected else {
            // Load data from cache if no internet connection
            loadWeatherFromCache()
            return
        }
        
        // Fetch data from API
        fetchWeatherFromAPI()
    }
    
    // MARK: - Private Methods

    /// Fetches weather data from the API.
    private func fetchWeatherFromAPI() {
        guard let coordinates else { return }
        
        isAPILoading = true
        
        // Fetch current weather from API
        weatherRepo.getCurrentWeather(coordinates: coordinates)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    // Log error and stop loading indicator
                    Log.shared.printLog(error)
                    self.isAPILoading = false
                }
            } receiveValue: { [weak self] output in
                guard let self else { return }
                // Update current weather
                currentWeather = output
                // Update city name if provided
                if let cityName = self.cityName {
                    self.currentWeather?.name = cityName
                }
                // Save current weather to cache
                saveCurrentWeatherToCache(currentWeather ?? output)
            }
            .store(in: &self.cancellables)
        
        // Fetch forecast data from API
        weatherRepo.getForecast(coordinates: coordinates)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    // Log error
                    Log.shared.printLog(error)
                }
            } receiveValue: {[weak self] forecastEntity in
                guard let self else { return }
                // Process and update daily forecast
                let forecastData = self.setDataAsPerDays(forecastList: forecastEntity.list)
                self.dailyForecast = forecastData
                // Save forecast to cache
                saveForecastToCache(forecastEntity)
                // Stop loading indicator
                isAPILoading = false
            }
            .store(in: &self.cancellables)
    }
    
    /// Processes forecast data to create a list of daily forecasts.
    ///
    /// - Parameter forecastList: The list of forecast entities.
    /// - Returns: An array of `DailyForecast` objects.
    private func setDataAsPerDays(forecastList: [ForecastListEntity]?) -> [DailyForecast] {
        guard let forecastList = forecastList, !forecastList.isEmpty else { return [] }
        
        // Group the forecast list by day
        let calendar = Calendar.current
        let groupedByDay = Dictionary(grouping: forecastList) { forecastItem -> Date in
            // Start of the day for the given date
            return calendar.startOfDay(for: forecastItem.dt)
        }
        
        // Sort the days to maintain chronological order
        let sortedDays = groupedByDay.keys.sorted()
        
        var dailyList = [DailyForecast]()
        
        // Limit the forecast to the next 5 days
        for (index, dayDate) in sortedDays.enumerated() {
            if index >= 5 {
                break
            } // Only include forecasts for the next 5 days
            
            // Get all forecasts for the current day
            guard let dailyForecasts = groupedByDay[dayDate] else { continue }
            
            // Calculate the maximum and minimum temperatures for the day
            let maxTemp = dailyForecasts.compactMap { $0.main.tempMax }.max() ?? 0
            let minTemp = dailyForecasts.compactMap { $0.main.tempMin }.min() ?? 0
            let temp = dailyForecasts.compactMap { $0.main.temp }.min() ?? 0
            let humidity = dailyForecasts.compactMap { $0.main.humidity }.min() ?? 0
            let windSpeed = dailyForecasts.compactMap { $0.wind.speed }.min() ?? 0
            
            // Use the first weather status of the day as a representative
            let status = dailyForecasts.first?.weather.first
            
            // Label the first day as "Today", others with the day name
            let dayLabel: String
            if index == 0 {
                dayLabel = "Today"
            } else {
                dayLabel = dayDate.day
            }
            
            // Create a DailyForecast object and add it to the list
            let forecastData = DailyForecast(
                maxTemp: maxTemp,
                minTemp: minTemp,
                day: dayLabel,
                descEntity: status,
                temp: temp,
                humidity: humidity,
                windSpeed: windSpeed
            )
            dailyList.append(forecastData)
        }
        
        return dailyList
    }
    // MARK: - Caching Methods
    
    /// Loads the current weather data from the cache.
    ///
    /// - Returns: A `CurrentWeatherEntity` object if available, else `nil`.
    private func loadCurrentWeatherFromCache() -> CurrentWeatherEntity? {
        // Fetch the most recent cached current weather
        if let realmCurrentWeather = RealmManager.sharedInstance.fetch(object: RealmCurrentWeatherEntity.self)
            .sorted(byKeyPath: "lastUpdated", ascending: false)
            .first {
            // Convert RealmCurrentWeatherEntity back to CurrentWeatherEntity
            let weatherData = CurrentWeatherEntity(
                name: realmCurrentWeather.name,
                coord: CoordinatesEntity(
                    lat: realmCurrentWeather.coord?.lat,
                    lon: realmCurrentWeather.coord?.lon
                ),
                main: realmCurrentWeather.main?.toEntity(),
                weather: realmCurrentWeather.weather.map { $0.toEntity() }
            )
            return weatherData
        }
        return nil
    }
    
    /// Saves the current weather data to the cache.
    ///
    /// - Parameter currentWeather: The `CurrentWeatherEntity` to cache.
    private func saveCurrentWeatherToCache(_ currentWeather: CurrentWeatherEntity) {
        let realmCurrentWeather = currentWeather.toRealmEntity()
        realmCurrentWeather.lastUpdated = Date() // Add a timestamp
        RealmManager.sharedInstance.asyncWrite { realm in
            // Delete previous cached data
            realm.delete(realm.objects(RealmCurrentWeatherEntity.self))
            // Add new data to cache
            realm.add(realmCurrentWeather)
        }
    }
    
    /// Loads the forecast data from the cache.
    ///
    /// - Returns: An array of `DailyForecast` objects if available, else `nil`.
    private func loadForecastFromCache() -> [DailyForecast]? {
        if let realmForecast = RealmManager.sharedInstance.fetch(object: RealmForecastEntity.self)
            .sorted(byKeyPath: "lastUpdated", ascending: false)
            .first {
            // Convert RealmForecastEntity back to [DailyForecast]
            return Array(realmForecast.dailyForecasts.map { $0.toEntity() })
        }
        return nil
    }
    
    /// Saves the forecast data to the cache.
    ///
    /// - Parameter forecast: The `ForecastEntity` to cache.
    private func saveForecastToCache(_ forecast: ForecastEntity) {
        let realmForecast = forecast.toRealmEntity()
        realmForecast.coordinates = RealmCoordinatesEntity(coordinates: self.coordinates)
        realmForecast.lastUpdated = Date() // Add a timestamp
        RealmManager.sharedInstance.asyncWrite { realm in
            // Delete previous cached data
            realm.delete(realm.objects(RealmForecastEntity.self))
            // Add new data to cache
            realm.add(realmForecast)
        }
    }
    
    /// Loads the weather data from the cache and updates the properties.
    private func loadWeatherFromCache() {
        if let cachedCurrentWeather = loadCurrentWeatherFromCache() {
            self.currentWeather = cachedCurrentWeather
            // Update city name if provided
            if let cityName = self.cityName {
                self.currentWeather?.name = cityName
            }
        } else {
            // Log if no cached current weather data is available
            Log.shared.printLog("No cached current weather data available.")
        }
        
        if let cachedDailyForecast = loadForecastFromCache() {
            self.dailyForecast = cachedDailyForecast
        } else {
            // Log if no cached forecast data is available
            Log.shared.printLog("No cached forecast data available.")
        }
    }

    // Wind Speed Conversion
    func metersPerSecondToKilometersPerHour(speed: Double) -> String {
        let speedInKmPerHour = speed * 3.6
        return String(format: "%.2f", speedInKmPerHour)
    }
}
