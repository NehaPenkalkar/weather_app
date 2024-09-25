//
//  InternetManager.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation
import Network
import SystemConfiguration

/// A manager class responsible for monitoring internet connectivity status.
/// Utilizes `NWPathMonitor` for real-time network changes and `SCNetworkReachability` for connectivity checks.
public class InternetManager {
    // MARK: - Properties
    
    /// A network path monitor to observe network changes.
    let monitor = NWPathMonitor()
    
    /// A dispatch queue for the network path monitor.
    let queue = DispatchQueue(label: "Monitor")
    
    /// A published property to monitor real-time network changes.
    @Published var checkRealTimeConnection = true // For monitoring real-time network changes
    
    // MARK: - Initializer
    
    /// Initializes a new instance of `InternetManager` and starts monitoring network changes.
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // Update the `checkRealTimeConnection` property based on network status.
                self?.checkRealTimeConnection = path.status == .satisfied
            }
        }
        // Start the network path monitor on the specified queue.
        monitor.start(queue: queue)
    }
    
    // MARK: - Connectivity Check
    
    /// A computed property that returns `true` if the internet is reachable, `false` otherwise.
    public var isConnected: Bool {

        // Initialize a zeroed-out IPv4 sockaddr_in structure.
        var noAddress = sockaddr_in(
            sin_len: 0,
            sin_family: 0,
            sin_port: 0,
            sin_addr: in_addr(s_addr: 0),
            sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)
        )
        noAddress.sin_len = UInt8(MemoryLayout.size(ofValue: noAddress))
        noAddress.sin_family = sa_family_t(AF_INET)

        // Create a reachability reference using the zeroed-out address.
        let defaultRouteReachability = withUnsafePointer(to: &noAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { noSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, noSockAddress)
            }
        }

        // Check if the reachability reference is valid.
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }

        // Determine if the network is reachable and doesn't require a connection.
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        let ret = (isReachable && !needsConnection)

        return ret
    }
}
