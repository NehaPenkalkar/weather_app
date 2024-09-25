//
//  CityEntity.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import RealmSwift

// MARK: CityEntity
public struct CityEntity: Codable, Hashable, Identifiable {
    public var id: String {
        return "\(lat) \(lon)"
    }
    
    public let name: String
    public let lat: Double
    public let lon: Double
    public let localNames: [String: String]?
    
    var localName: String {
        localNames?[Locale.current.language.languageCode?.identifier ?? "en"] ?? name
    }
    
    var coordinates: CoordinatesEntity {
        CoordinatesEntity(lat: lat, lon: lon)
    }
    
    func toRealmCityEntity() -> RealmCityEntity {
        // Create a RealmCityEntity using the data from the Codable entity
        let realmCity = RealmCityEntity(
            name: self.name,
            lat: self.lat,
            lon: self.lon,
            localNames: self.localNames
        )
        return realmCity
    }
    
    public init(name: String, lat: Double, lon: Double, localNames: [String: String]?) {
        self.name = name
        self.lat = lat
        self.lon = lon
        self.localNames = localNames
    }
}

// MARK: RealmCityEntity
class RealmCityEntity: Object {
    @Persisted(primaryKey: true) var id: String = ""  // Primary key (lat + lon)
    @Persisted var name: String = ""
    @Persisted var lat: Double = 0.0
    @Persisted var lon: Double = 0.0
    @Persisted var localNamesJSON: String?  // JSON string to store local names

    // Derived property for local names
    var localNames: [String: String]? {
        get {
            guard let jsonString = localNamesJSON,
                  let data = jsonString.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode([String: String].self, from: data)
        }
        set {
            if let newValue = newValue,
               let jsonData = try? JSONEncoder().encode(newValue),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                localNamesJSON = jsonString
            } else {
                localNamesJSON = nil
            }
        }
    }
    
    // Initializer to create a RealmCityEntity from CityEntity data
    convenience init(name: String, lat: Double, lon: Double, localNames: [String: String]?) {
        self.init()
        self.name = name
        self.lat = lat
        self.lon = lon
        self.id = "\(lat) \(lon)"  // Primary key based on lat and lon
        self.localNames = localNames
    }
}
