//
//  ForecastEntity.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import RealmSwift

public struct ForecastEntity: Codable {
    public let list: [ForecastListEntity]
    
    func toRealmEntity() -> RealmForecastEntity {
        let realmEntity = RealmForecastEntity(forecast: self)
        return realmEntity
    }
    
    public init(list: [ForecastListEntity]) {
        self.list = list
    }
}

class RealmForecastEntity: Object {
    @Persisted(primaryKey: true) var id: ObjectId = ObjectId.generate()
    @Persisted var list: List<RealmForecastListEntity> = List<RealmForecastListEntity>()
    @Persisted var dailyForecasts: List<RealmDailyForecast> = List<RealmDailyForecast>()
    @Persisted var coordinates: RealmCoordinatesEntity?
    @Persisted var lastUpdated: Date?
    
    // Initializer
    convenience init(forecast: ForecastEntity) {
        self.init()
        let realmList = forecast.list.map { $0.toRealmEntity() }
        self.list.append(objectsIn: realmList)
        
        // Convert the forecast list into daily forecasts
        let forecastData = setDataAsPerDays(forecastList: forecast.list)
        let realmDailyForecasts = forecastData.map { $0.toRealmEntity() }
        self.dailyForecasts.append(objectsIn: realmDailyForecasts)
    }
    
    private func setDataAsPerDays(forecastList: [ForecastListEntity]) -> [DailyForecast] {
        guard !forecastList.isEmpty else { return [] }
        
        // Group the forecast list by day (Date)
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
            let dailyForecast = DailyForecast(
                maxTemp: maxTemp,
                minTemp: minTemp,
                day: dayLabel,
                descEntity: status,
                temp: temp,
                humidity: humidity,
                windSpeed: windSpeed
            )
            dailyList.append(dailyForecast)
        }
        
        return dailyList
    }
}

public struct ForecastListEntity: Codable, Hashable {
    public let dt: Date
    public let main: MainEntity
    public let weather: [WeatherDescriptionEntity]
    public let wind: WindEntity
    
    func toRealmEntity() -> RealmForecastListEntity {
        let realmEntity = RealmForecastListEntity(forecastList: self)
        return realmEntity
    }
    
    public init(dt: Date, main: MainEntity, weather: [WeatherDescriptionEntity], wind: WindEntity) {
        self.dt = dt
        self.main = main
        self.weather = weather
        self.wind = wind
    }
}

class RealmForecastListEntity: EmbeddedObject {
    @Persisted var dt: Date
    @Persisted var main: RealmMainEntity?
    @Persisted var weather: List<RealmWeatherDescriptionEntity>
    @Persisted var wind: RealmWindEntity?
    
    // Initializer
    convenience init(forecastList: ForecastListEntity) {
        self.init()
        self.dt = forecastList.dt
        self.main = RealmMainEntity(main: forecastList.main)
        let realmWeatherList = forecastList.weather.map { RealmWeatherDescriptionEntity(weatherDescription: $0) }
        self.weather.append(objectsIn: realmWeatherList)
        self.wind = RealmWindEntity(wind: forecastList.wind)
    }
}

struct DailyForecast: Codable, Hashable {
    let maxTemp: Double
    let minTemp: Double
    let day: String
    let descEntity: WeatherDescriptionEntity?
    
    let temp: Double
    let humidity: Int
    let windSpeed: Double
    
    func toRealmEntity() -> RealmDailyForecast {
        let realmEntity = RealmDailyForecast(dailyForecast: self)
        return realmEntity
    }
    
    public init(maxTemp: Double, minTemp: Double, day: String, descEntity: WeatherDescriptionEntity?, temp: Double, humidity: Int, windSpeed: Double) {
        self.maxTemp = maxTemp
        self.minTemp = minTemp
        self.day = day
        self.descEntity = descEntity
        self.temp = temp
        self.humidity = humidity
        self.windSpeed = windSpeed
    }
}

class RealmDailyForecast: EmbeddedObject {
    @Persisted var maxTemp: Double
    @Persisted var minTemp: Double
    @Persisted var day: String
    @Persisted var descEntity: RealmWeatherDescriptionEntity?
    
    @Persisted var temp: Double
    @Persisted var humidity: Int
    @Persisted var windSpeed: Double
    
    // Initializer
    convenience init(dailyForecast: DailyForecast) {
        self.init()
        self.maxTemp = dailyForecast.maxTemp
        self.minTemp = dailyForecast.minTemp
        self.day = dailyForecast.day
        if let descEntity = dailyForecast.descEntity {
            self.descEntity = RealmWeatherDescriptionEntity(weatherDescription: descEntity)
        }
    }
    
    func toEntity() -> DailyForecast {
        return DailyForecast(
            maxTemp: self.maxTemp,
            minTemp: self.minTemp,
            day: self.day,
            descEntity: self.descEntity?.toEntity(),
            temp: self.temp,
            humidity: self.humidity,
            windSpeed: self.windSpeed
        )
    }
}
