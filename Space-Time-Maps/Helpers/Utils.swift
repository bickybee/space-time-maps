//
//  Helpers.swift
//  Space-Time-Maps
//
//  Created by Vicky on 13/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import UIKit.UIColor

class Utils {
    
    static func secondsToString(seconds: Int) -> String {
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .full
        let formattedString = formatter.string(from: TimeInterval(seconds)) ?? "error"
        
        return formattedString
    }
    
    static func currentTime() -> Double? {
        
        // Get current time
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: Date())
        
        // Get components of time
        guard let currentHour = currentComponents.hour else { return nil }
        guard let currentMinute = currentComponents.minute else { return nil }
        let currentTime = TimeInterval.from(hours: currentHour) + TimeInterval.from(minutes: currentMinute)
        
        return currentTime
        
    }
    
    static func defaultPlaces() -> [Place] {
        var places = [Place]()
        places.append(Place(name: "Bahen Centre", coordinate: Coordinate(lat: 43.65964259999999, lon: -79.39766759999999), placeID: "ChIJV8llUcc0K4gRe7a0R0E4WWQ", isInItinerary: false))
        places.append(Place(name: "Art Gallery of Ontario", coordinate: Coordinate(lat: 43.6536066, lon: -79.39251229999999), placeID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", isInItinerary: false))
        places.append(Place(name: "Casa Loma", coordinate: Coordinate(lat: 43.67803709999999, lon: -79.4094439), placeID: "ChIJs6Elz500K4gRT1jWAsHIfGE", isInItinerary: false))
        return places
    }
    
    
    
}
