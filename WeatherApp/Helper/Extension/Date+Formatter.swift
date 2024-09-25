//
//  Date+Formatter.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation

extension Date {
    var day: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "eee"
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: self)
    }
}
