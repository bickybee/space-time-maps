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
            destinations.sort(by: { $0.startTime < $1.startTime })
        }
    }
    var route : Route?
    var travelMode : TravelMode
    
}
