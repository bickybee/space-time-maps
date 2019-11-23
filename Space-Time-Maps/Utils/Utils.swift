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
    
    private static let starterPlaces : [Place] = [
        Place(name: "Gladstone Hotel", coordinate: Coordinate(lat: 43.642698, lon: -79.426906), placeID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"),
        Place(name: "Art Gallery of Ontario", coordinate: Coordinate(lat: 43.6536066, lon: -79.39251229999999), placeID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"),
        Place(name: "Casa Loma", coordinate: Coordinate(lat: 43.67803709999999, lon: -79.4094439), placeID: "ChIJs6Elz500K4gRT1jWAsHIfGE"),
        Place(name: "Christie Pits Park", coordinate: Coordinate(lat: 43.6645888, lon: -79.4206809), placeID: "ChIJ8f_In4s0K4gRRK-KutieqXA"),
        Place(name: "Evergreen Brick Works", coordinate: Coordinate(lat: 43.6846206, lon: -79.3654466), placeID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"),
        Place(name: "The Selby", coordinate: Coordinate(lat: 43.6710771, lon: -79.37722099999999), placeID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w")
    ]
    
    static let starterPlaceDict : TimeDict = [PlacePair(startID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", endID: "ChIJ8f_In4s0K4gRRK-KutieqXA"): 647.0, PlacePair(startID: "ChIJwScp6qo1K4gRcuheo9LY6ZI", endID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"): 1246.0, PlacePair(startID: "ChIJ8f_In4s0K4gRRK-KutieqXA", endID: "ChIJs6Elz500K4gRT1jWAsHIfGE"): 361.0, PlacePair(startID: "ChIJ8f_In4s0K4gRRK-KutieqXA", endID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"): 872.0, PlacePair(startID: "ChIJs6Elz500K4gRT1jWAsHIfGE", endID: "ChIJs6Elz500K4gRT1jWAsHIfGE"): 0.0, PlacePair(startID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", endID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"): 756.0, PlacePair(startID: "ChIJsXBSVKTM1IkRtVcT_EMpDho", endID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"): 0.0, PlacePair(startID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w", endID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"): 0.0, PlacePair(startID: "ChIJwScp6qo1K4gRcuheo9LY6ZI", endID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"): 1048.0, PlacePair(startID: "ChIJs6Elz500K4gRT1jWAsHIfGE", endID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"): 984.0, PlacePair(startID: "ChIJsXBSVKTM1IkRtVcT_EMpDho", endID: "ChIJ8f_In4s0K4gRRK-KutieqXA"): 1095.0, PlacePair(startID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w", endID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"): 1523.0, PlacePair(startID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", endID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"): 0.0, PlacePair(startID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w", endID: "ChIJ8f_In4s0K4gRRK-KutieqXA"): 909.0, PlacePair(startID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", endID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"): 848.0, PlacePair(startID: "ChIJ8f_In4s0K4gRRK-KutieqXA", endID: "ChIJ8f_In4s0K4gRRK-KutieqXA"): 0.0, PlacePair(startID: "ChIJ8f_In4s0K4gRRK-KutieqXA", endID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"): 580.0, PlacePair(startID: "ChIJwScp6qo1K4gRcuheo9LY6ZI", endID: "ChIJ8f_In4s0K4gRRK-KutieqXA"): 575.0, PlacePair(startID: "ChIJs6Elz500K4gRT1jWAsHIfGE", endID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"): 864.0, PlacePair(startID: "ChIJsXBSVKTM1IkRtVcT_EMpDho", endID: "ChIJs6Elz500K4gRT1jWAsHIfGE"): 880.0, PlacePair(startID: "ChIJwScp6qo1K4gRcuheo9LY6ZI", endID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"): 786.0, PlacePair(startID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w", endID: "ChIJs6Elz500K4gRT1jWAsHIfGE"): 717.0, PlacePair(startID: "ChIJs6Elz500K4gRT1jWAsHIfGE", endID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"): 727.0, PlacePair(startID: "ChIJwScp6qo1K4gRcuheo9LY6ZI", endID: "ChIJs6Elz500K4gRT1jWAsHIfGE"): 966.0, PlacePair(startID: "ChIJ8f_In4s0K4gRRK-KutieqXA", endID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"): 1027.0, PlacePair(startID: "ChIJs6Elz500K4gRT1jWAsHIfGE", endID: "ChIJ8f_In4s0K4gRRK-KutieqXA"): 364.0, PlacePair(startID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", endID: "ChIJs6Elz500K4gRT1jWAsHIfGE"): 635.0, PlacePair(startID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o", endID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"): 1024.0, PlacePair(startID: "ChIJ8f_In4s0K4gRRK-KutieqXA", endID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"): 664.0, PlacePair(startID: "ChIJwScp6qo1K4gRcuheo9LY6ZI", endID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"): 0.0, PlacePair(startID: "ChIJs6Elz500K4gRT1jWAsHIfGE", endID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"): 685.0, PlacePair(startID: "ChIJsXBSVKTM1IkRtVcT_EMpDho", endID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"): 1069.0, PlacePair(startID: "ChIJsXBSVKTM1IkRtVcT_EMpDho", endID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w"): 697.0, PlacePair(startID: "ChIJsXBSVKTM1IkRtVcT_EMpDho", endID: "ChIJwScp6qo1K4gRcuheo9LY6ZI"): 1686.0, PlacePair(startID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w", endID: "ChIJvRlT7cU0K4gRr0bg7VV3J9o"): 859.0, PlacePair(startID: "ChIJZ2alrsfL1IkRXnxh_Pw8p0w", endID: "ChIJsXBSVKTM1IkRtVcT_EMpDho"): 538.0]
    
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
