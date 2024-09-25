//
//  Double+ConvertToString.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation

extension Double {
    var toString: String {
        return String(format: "%.1f", self) + "°"
    }
}
