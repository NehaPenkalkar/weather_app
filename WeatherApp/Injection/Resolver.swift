//
//  Resolver.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import Resolver
import RealmSwift

extension Resolver: @retroactive ResolverRegistering {
    public static func registerAllServices() {
        
        register { DefaultWeatherRepository() }.implements(WeatherRepository.self)
        
        // MARK: - LOCAL DATABASE
        
        register(Realm.Configuration.self) { _ in
            Realm.Configuration(schemaVersion: 1) // Change version when updating properties
        }
        register(Realm.self) { r in
            do {
                return try Realm(configuration: r.resolve(Realm.Configuration.self))
            } catch {
                // Handle the error properly, e.g., logging or throwing a custom error.
                fatalError("Failed to initialize Realm: \(error.localizedDescription)")
            }
        }
    }
}
