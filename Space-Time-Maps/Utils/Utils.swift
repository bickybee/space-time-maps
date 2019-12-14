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
    
    private static let roundHourTo : Double = 0.25
    
    static let starterPlaces : [Place] = [
        Place(name: "Gladstone Hotel", coordinate: Coordinate(latitude: 43.642698, longitude: -79.426906), placeID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"),
        Place(name: "Art Gallery of Ontario", coordinate: Coordinate(latitude: 43.6536066, longitude: -79.39251229999999), placeID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"),
        Place(name: "Casa Loma", coordinate: Coordinate(latitude: 43.67803709999999, longitude: -79.4094439), placeID: "ChIJs6Elz500K4gRT1jWAsHIfGE"),
        Place(name: "Christie Pits Park", coordinate: Coordinate(latitude: 43.6645888, longitude: -79.4206809), placeID: "ChIJ8f_In4s0K4gRRK-KutieqXA"),
        Place(name: "Evergreen Brick Works", coordinate: Coordinate(latitude: 43.6846206, longitude: -79.3654466), placeID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"),
        Place(name: "The Selby", coordinate: Coordinate(latitude: 43.6710771, longitude: -79.37722099999999), placeID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w")
    ]
    
    static let tutorialPlaceGroups1 : [PlaceGroup] = [
        PlaceGroup(name: "", places:
            [Place(name: "Gladstone Hotel", coordinate: Coordinate(latitude: 43.642698, longitude: -79.426906), placeID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"),
            Place(name: "Art Gallery of Ontario", coordinate: Coordinate(latitude: 43.6536066, longitude: -79.39251229999999), placeID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"),
            Place(name: "Casa Loma", coordinate: Coordinate(latitude: 43.67803709999999, longitude: -79.4094439), placeID: "ChIJs6Elz500K4gRT1jWAsHIfGE")
        ],
                   kind: .none)
    ]
    
    static let tutorialPlaceGroups2 : [PlaceGroup] = [
        PlaceGroup(name: "", places:
            [Place(name: "The Selby", coordinate: Coordinate(latitude: 43.6710771, longitude: -79.37722099999999), placeID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"),
        ],
                   kind: .none),
        PlaceGroup(name: "one of", places:
            [Place(name: "Christie Pits Park", coordinate: Coordinate(latitude: 43.6645888, longitude: -79.4206809), placeID: "ChIJ8f_In4s0K4gRRK-KutieqXA"),
            Place(name: "Evergreen Brick Works", coordinate: Coordinate(latitude: 43.6846206, longitude: -79.3654466), placeID: "ChIJsXBSVKTM1IkRtVcT_EMpDho")
        ],
                   kind: .oneOf),
        PlaceGroup(name: "as many of", places:
            [Place(name: "Art Gallery of Ontario", coordinate: Coordinate(latitude: 43.6536066, longitude: -79.39251229999999), placeID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"),
            Place(name: "Casa Loma", coordinate: Coordinate(latitude: 43.67803709999999, longitude: -79.4094439), placeID: "ChIJs6Elz500K4gRT1jWAsHIfGE"),
            Place(name: "Gladstone Hotel", coordinate: Coordinate(latitude: 43.642698, longitude: -79.426906), placeID: "ChIJwScp6qo1K4gRcuheo9LY6ZI")
            
        ],
                   kind: .asManyOf),
    ]
    
    static let taskPlaceGroups : [PlaceGroup] = [
        PlaceGroup(name: "", places:
            [Place(name: "Home", coordinate: Coordinate(latitude: 43.6710771, longitude: -79.37722099999999), placeID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"),
             Place(name: "Karine’s", coordinate: Coordinate(latitude: 43.6537184, longitude: -79.3909035), placeID: "ChIJReTjXM80K4gRRJolJCumgyM"),
             Place(name: "Saving Grace", coordinate: Coordinate(latitude: 43.6509022, longitude: -79.4123894), placeID: "ChIJQTNua-U0K4gRbpvCyW4X6ZA"),
             Place(name: "Avenue Arts School", coordinate: Coordinate(latitude: 43.6853238, longitude: -79.4012777), placeID: "ChIJWRmtuF0zK4gRsuS06pUdC84"),
             Place(name: "Blue Banana Market", coordinate: Coordinate(latitude: 43.65565, longitude: -79.402675), placeID: "ChIJ3QAWAcI0K4gRRk03JfzJW5Q"),
             Place(name: "DeSerres", coordinate: Coordinate(latitude: 43.64767370000001, longitude: -79.39621300000002), placeID: "ChIJccHtmds0K4gRL3Z505NJDWI"),
             Place(name: "Rexall Pharmacy", coordinate: Coordinate(latitude: 43.6577013, longitude: -79.40038009999999), placeID: "ChIJZ1kGVcA0K4gRlJeJPAwWkVc"),
             Place(name: "Toronto Public Library - Sanderson Branch", coordinate: Coordinate(latitude: 43.652106, longitude: -79.4056243), placeID: "ChIJV7V8AVLL1IkRQnQgsM9HkDc"),
             Place(name: "John's House", coordinate: Coordinate(latitude: 43.6660011, longitude: -79.4112152), placeID: "ChIJs6TFeJE0K4gRCAPffqYPbsQ")
        ],
                   kind: .none)
    ]
    

    
    static func secondsToRelativeTimeString(seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        let formattedString = formatter.string(from: seconds) ?? "error"
        
        return formattedString
    }
    
    static func secondsToAbsoluteTimeString(_ seconds: TimeInterval) -> String {
        let hours = seconds.inHours()
        var hour = floor(hours)
        let minutes = (hours - hour) * 60.0
        
        var midday : String
        if hour >= 12 {
            if hour != 12 {
                hour -= 12
            }
            midday = "PM"
        } else {
            midday = "PM"
        }
        
        let hourString = "\(Int(hour))"
        let minString = minutes < 10 ? "0\(Int(minutes))" : "\(Int(minutes))"
        let timeString = hourString + ":" + minString + midday
        return timeString
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
        places.append(contentsOf: starterPlaces)
        return places
    }
    
    static func defaultPlacesGroups() -> [PlaceGroup] {
        
        var groups = [PlaceGroup]()
        
        let places0 = PlaceGroup(name: "", places: Array(starterPlaces[0...1]), kind: .none)
        groups.append(places0)
        
        let places1 = PlaceGroup(name: "one of", places: Array(starterPlaces[2...3]), kind: .oneOf)
        groups.append(places1)
        
        let places2 = PlaceGroup(name: "as many of", places: Array(starterPlaces[4...5]), kind: .asManyOf)
        groups.append(places2)
        
        return groups
    }
    
    static func getTaskPlaceGroups() -> [PlaceGroup] {
        
        return taskPlaceGroups
    }
    
    static func floorHour(_ hour: Double) -> Double {
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let clampedHour = floor(hour) + floor(decimal / Utils.roundHourTo) * Utils.roundHourTo
        return clampedHour
    }
    
    static func ceilHour(_ hour: Double) -> Double {
        let decimal = hour.truncatingRemainder(dividingBy: 1.0)
        let clampedHour = floor(hour) + ceil(decimal / Utils.roundHourTo) * Utils.roundHourTo
        return clampedHour
    }
    
    static func ceilTime(_ time: TimeInterval) -> TimeInterval {
        let hour = time.inHours()
        let clamped = ceilHour(hour)
        return TimeInterval.from(hours: clamped)
    }
    
    static func floorTime(_ time: TimeInterval) -> TimeInterval {
        let hour = time.inHours()
        let clamped = floorHour(hour)
        return TimeInterval.from(hours: clamped)
    }
    
}
