//
//  Data+Extension.swift
//  WeatherApp
//
//  Created by Neha Penkalkar on 25/09/24.
//

import Foundation

public extension Data {
    var prettyPrint: String {
        var string = ""
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: self, options: [])
            let jsonData = jsonToData(jsonObject)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                string = jsonString
            }
        } catch {
            string = "Error pretty-printing JSON: \(error.localizedDescription)"
        }
        
        return string
    }
    
    private func jsonToData(_ obj: Any) -> Data {
        do {
            if JSONSerialization.isValidJSONObject(obj) {
                return try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
            } else {
                Log.shared.printLog("Object cannot be converted to json")
                return Data()
            }
            
        } catch {
            return Data()
        }
    }
}
