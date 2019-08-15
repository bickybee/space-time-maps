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
    
    static func colorAlongGradient(start: UIColor, middle: UIColor, end: UIColor, fraction: CGFloat) -> UIColor {
        guard (0 <= fraction) && (fraction <= 1) else { return start }
        
        if fraction < 0.5 {
            return colorAlongGradient(start: start, end: middle, fraction: fraction / 0.5)
        } else {
            return colorAlongGradient(start: middle, end: end, fraction: (fraction - 0.5) / 0.5)
        }
    }
    
    static func colorAlongGradient(start: UIColor, end: UIColor, fraction: CGFloat) -> UIColor {
        guard (0 <= fraction) && (fraction <= 1) else { return start }
        
        // Get color components
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        guard start.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return start }
        guard end.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return start }
        
        // Return colour along gradient
        return UIColor(red: CGFloat(r1 + (r2 - r1) * fraction),
                       green: CGFloat(g1 + (g2 - g1) * fraction),
                       blue: CGFloat(b1 + (b2 - b1) * fraction),
                       alpha: CGFloat(a1 + (a2 - a1) * fraction))
    }
    
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
        let currentTime = Double(currentHour) + (Double(currentMinute + 1) / 60.0) // 1 min in future :-)
        
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
