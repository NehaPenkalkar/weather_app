//
//  CurrentWeatherEntity.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import RealmSwift

public struct CurrentWeatherEntity: Codable {
    public var name: String?
    public var coord: CoordinatesEntity?
    public var main: MainEntity?
    public var wind: WindEntity?
    public var weather: [WeatherDescriptionEntity]?
    
    func toRealmEntity() -> RealmCurrentWeatherEntity {
        let realmEntity = RealmCurrentWeatherEntity(currentWeather: self)
        return realmEntity
    }
    
    public init(name: String? = nil, coord: CoordinatesEntity? = nil, main: MainEntity? = nil, weather: [WeatherDescriptionEntity]? = nil) {
        self.name = name
        self.coord = coord
        self.main = main
        self.weather = weather
    }
}

class RealmCurrentWeatherEntity: Object {
    @Persisted(primaryKey: true) var id: ObjectId = ObjectId.generate()
    @Persisted var name: String?
    @Persisted var coord: RealmCoordinatesEntity?
    @Persisted var main: RealmMainEntity?
    @Persisted var wind: RealmWindEntity? // Mark wind as optional
    @Persisted var weather: List<RealmWeatherDescriptionEntity>
    @Persisted var lastUpdated: Date? // Add this property for timestamp
    
    // Initializer
    convenience init(currentWeather: CurrentWeatherEntity) {
        self.init()
        self.name = currentWeather.name
        self.coord = RealmCoordinatesEntity(coordinates: currentWeather.coord)
        self.main = RealmMainEntity(main: currentWeather.main)
        let realmWeatherList = currentWeather.weather?.map { RealmWeatherDescriptionEntity(weatherDescription: $0) } ?? []
        self.weather.append(objectsIn: realmWeatherList)
        self.wind = RealmWindEntity(wind: currentWeather.wind) // Initialize wind if available
    }
}

public struct WindEntity: Codable, Equatable, Hashable {
    public var speed: Double?
    public var deg: Double?
    
    func toRealmEntity() -> RealmWindEntity {
        let realmEntity = RealmWindEntity(wind: self)
        return realmEntity
    }
    
    public init(speed: Double? = nil, deg: Double? = nil) {
        self.speed = speed
        self.deg = deg
    }
}

class RealmWindEntity: EmbeddedObject {
    @Persisted var speed: Double?
    @Persisted var deg: Double?
    
    // Initializer
    convenience init(wind: WindEntity?) {
        self.init()
        self.speed = wind?.speed
        self.deg = wind?.deg
    }
}

public struct CoordinatesEntity: Codable {
    public var lat: Double?
    public var lon: Double?
    
    func toRealmEntity() -> RealmCoordinatesEntity {
        let realmEntity = RealmCoordinatesEntity(coordinates: self)
        return realmEntity
    }
    
    public init(lat: Double? = nil, lon: Double? = nil) {
        self.lat = lat
        self.lon = lon
    }
}

class RealmCoordinatesEntity: EmbeddedObject {
    @Persisted var lat: Double?
    @Persisted var lon: Double?
    @Persisted var lastUpdated: Date? // Add this property for timestamp
    
    // Initializer
    convenience init(coordinates: CoordinatesEntity?) {
        self.init()
        guard let coordinates = coordinates else { return }
        self.lat = coordinates.lat
        self.lon = coordinates.lon
    }
}

public struct MainEntity: Codable, Hashable {
    public var humidity: Int?
    public var temp: Double?
    public var tempMax: Double?
    public var tempMin: Double?
    
    func toRealmEntity() -> RealmMainEntity {
        let realmEntity = RealmMainEntity(main: self)
        return realmEntity
    }
    
    enum CodingKeys: String, CodingKey {
        case humidity
        case temp
        case tempMax = "temp_max"
        case tempMin = "temp_min"
    }
    
    public init(humidity: Int? = nil, temp: Double? = nil, tempMax: Double? = nil, tempMin: Double? = nil) {
        self.humidity = humidity
        self.temp = temp
        self.tempMax = tempMax
        self.tempMin = tempMin
    }
}

class RealmMainEntity: EmbeddedObject {
    @Persisted var humidity: Int?
    @Persisted var temp: Double?
    @Persisted var tempMax: Double?
    @Persisted var tempMin: Double?
    
    // Initializer
    convenience init(main: MainEntity?) {
        self.init()
        guard let main = main else { return }
        self.humidity = main.humidity
        self.temp = main.temp
        self.tempMax = main.tempMax
        self.tempMin = main.tempMin
    }
    
    func toEntity() -> MainEntity {
        return MainEntity(
            humidity: self.humidity,
            temp: self.temp,
            tempMax: self.tempMax,
            tempMin: self.tempMin
        )
    }
}

public struct WeatherDescriptionEntity: Codable, Hashable {
    public var main: WeatherStatus?
    public var description: String?
    
    func toRealmEntity() -> RealmWeatherDescriptionEntity {
        let realmEntity = RealmWeatherDescriptionEntity(weatherDescription: self)
        return realmEntity
    }
    
    public init(main: WeatherStatus? = nil, description: String? = nil) {
        self.main = main
        self.description = description
    }
}

class RealmWeatherDescriptionEntity: EmbeddedObject {
    @Persisted var mainRawValue: String?
    @Persisted var descriptionText: String?
    
    var main: WeatherStatus? {
        get {
            guard let rawValue = mainRawValue else { return nil }
            return WeatherStatus(rawValue: rawValue)
        }
        set {
            mainRawValue = newValue?.rawValue
        }
    }
    
    // Initializer
    convenience init(weatherDescription: WeatherDescriptionEntity?) {
        self.init()
        guard let weatherDescription = weatherDescription else { return }
        self.mainRawValue = weatherDescription.main?.rawValue
        self.descriptionText = weatherDescription.description
    }
    
    func toEntity() -> WeatherDescriptionEntity {
           return WeatherDescriptionEntity(
               main: self.main,
               description: self.descriptionText
           )
       }
}
