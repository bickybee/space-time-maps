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

typealias Route = [Leg]

struct Itinerary {
    
    var destinations = [Destination]() {
        didSet {
            destinations.sort(by: { $0.startTime < $1.startTime })
        }
    }
    
    var route : [Leg] {
        didSet {
            route.sort(by: { $0.startTime < $1.startTime })
        }
    }
    
    var duration : TimeInterval {
        var totalDuration = TimeInterval(0)
        route.forEach({leg in
            totalDuration += leg.duration
        })
        return totalDuration
    }
    
    var travelMode : TravelMode
    
}
