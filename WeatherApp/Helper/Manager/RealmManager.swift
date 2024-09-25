//
//  RealmManager.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import RealmSwift
import Resolver

/// A singleton class that manages interactions with the Realm database.
/// Provides methods for fetching, saving, updating, and deleting objects, as well as performing asynchronous writes.
public class RealmManager {
    // MARK: - Properties
    
    /// The Realm database instance.
    private let database: Realm
    
    /// The shared singleton instance of `RealmManager`.
    static let sharedInstance = RealmManager()
    
    // MARK: - Initializer
    
    /// Private initializer for the Realm manager.
    /// Initializes the Realm database and handles any errors by crashing with a fatal error.
    private init() {
        do {
            // Attempt to initialize the Realm database.
            database = try Realm()
        } catch {
            // If initialization fails, crash the application with the error description.
            fatalError(error.localizedDescription)
        }
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the Realm database to ensure it has the latest data.
    public func refresh() {
        database.refresh()
    }
    
    /// Retrieves all objects of the specified type from the database.
    ///
    /// - Parameter object: The type of object to retrieve.
    /// - Returns: A `Results` collection containing all objects of the specified type.
    public func fetch<T: Object>(object: T.Type) -> Results<T> {
        self.refresh()
        return database.objects(T.self)
    }
    
    /// Writes the given object to the database.
    ///
    /// - Parameters:
    ///   - object: The object to be saved.
    ///   - errorHandler: A closure to handle any errors that occur during the write operation. Defaults to a closure that does nothing.
    public func save<T: Object>(
        object: T,
        _ errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in
            // This closure is intentionally left empty to provide a default no-op (no operation) behavior.
            // The caller can pass their own error handling logic if desired, but if they choose not to,
            // the function will simply do nothing in case of an error, preventing any crashes.
        }
    ) {
        do {
            try database.write {
                database.add(object)
            }
        } catch {
            errorHandler(error)
        }
    }
    
    /// Updates the given object in the database. If the object does not exist, it will be added.
    ///
    /// - Parameters:
    ///   - object: The object to be updated.
    ///   - errorHandler: A closure to handle any errors that occur during the update operation. Defaults to a closure that does nothing.
    public func update<T: Object>(
        object: T,
        errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in
            // This closure is intentionally left empty to provide a default no-op (no operation) behavior.
            // The caller can pass their own error handling logic if desired, but if they choose not to,
            // the function will simply do nothing in case of an error, preventing any crashes.
        }
    ) {
        do {
            try database.write {
                database.add(object, update: .all)
            }
        } catch {
            errorHandler(error)
        }
    }
    
    /// Deletes the given object from the database if it exists.
    ///
    /// - Parameters:
    ///   - object: The object to be deleted.
    ///   - errorHandler: A closure to handle any errors that occur during the delete operation. Defaults to a closure that does nothing.
    public func delete<T: Object>(
        object: T,
        errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in
            // This closure is intentionally left empty to provide a default no-op (no operation) behavior.
            // The caller can pass their own error handling logic if desired, but if they choose not to,
            // the function will simply do nothing in case of an error, preventing any crashes.
        }
    ) {
        do {
            try database.write {
                database.delete(object)
            }
        } catch {
            errorHandler(error)
        }
    }
    
    /// Deletes all data from the database, including all objects of all types.
    ///
    /// - Parameter errorHandler: A closure to handle any errors that occur during the delete operation. Defaults to a closure that does nothing.
    public func deleteAll(
        errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in
            // This closure is intentionally left empty to provide a default no-op (no operation) behavior.
            // The caller can pass their own error handling logic if desired, but if they choose not to,
            // the function will simply do nothing in case of an error, preventing any crashes.
        }
    ) {
        do {
            try database.write {
                database.deleteAll()
            }
        } catch {
            errorHandler(error)
        }
    }
    
    /// Performs an asynchronous write operation on the database.
    ///
    /// - Parameters:
    ///   - errorHandler: A closure to handle any errors that occur during the write operation. Defaults to a closure that does nothing.
    ///   - action: A closure containing the write logic to be performed.
    ///   - completion: An optional closure to be executed upon completion of the write operation.
    public func asyncWrite(
        errorHandler: @escaping ((_ error: Swift.Error) -> Void) = { _ in
            // This closure is intentionally left empty to provide a default no-op (no operation) behavior.
            // The caller can pass their own error handling logic if desired, but if they choose not to,
            // the function will simply do nothing in case of an error, preventing any crashes.
        },
        action: @escaping ((Realm) -> Void),
        completion: (() -> Void)? = nil
    ) {
        let config = self.database.configuration
        DispatchQueue(label: "background").async {
            autoreleasepool {
                self.performRealmWrite(with: config, action: action, completion: completion, errorHandler: errorHandler)
            }
        }
    }

    private func performRealmWrite(
        with configuration: Realm.Configuration,
        action: @escaping ((Realm) -> Void),
        completion: (() -> Void)?,
        errorHandler: @escaping ((_ error: Swift.Error) -> Void)
    ) {
        do {
            // Initialize a new Realm instance with the same configuration.
            let realm = try Realm(configuration: configuration)
            
            // Perform the write operation.
            try realm.write {
                action(realm)
            }
            
            // Handle completion
            self.handleCompletion(completion)
            
        } catch {
            errorHandler(error)
        }
    }

    private func handleCompletion(_ completion: (() -> Void)?) {
        guard let completion = completion else { return }
        DispatchQueue.main.async {
            completion()
            self.refresh()
        }
    }
}
