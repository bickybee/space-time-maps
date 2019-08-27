//
//  Itinerary.swift
//  Space-Time-Maps
//
//  Created by Vicky on 29/07/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

enum TravelMode : String {
    case driving, walking, bicycling, transit
}

struct Itinerary {
    
    var destinations = [Destination]() {
        didSet {
            destinations.sort(by: { $0.timing.start < $1.timing.start })
        }
    }
    
    var route : [Leg] {
        didSet {
            route.sort(by: { $0.timing.start < $1.timing.start })
        }
    }
    
    var duration : TimeInterval {
        var totalDuration = TimeInterval(0)
        route.forEach({leg in
            totalDuration += leg.timing.duration
        })
        destinations.forEach({dest in
            totalDuration += dest.timing.duration
        })
        return totalDuration
    }
    
    var travelTime : TimeInterval {
        var totalTravelTime = TimeInterval(0)
        route.forEach({leg in
            totalTravelTime += leg.travelTiming.duration
        })
        return totalTravelTime
    }
    
    var travelMode : TravelMode
    
}
