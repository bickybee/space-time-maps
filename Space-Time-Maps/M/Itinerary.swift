//
//  Itinerary.swift
//  Space-Time-Maps
//
//  Created by Vicky on 29/07/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

// Data on our current PLAN!

enum TravelMode : String {
    case driving, walking, bicycling, transit
}

class Itinerary {
    
    var schedule = [ScheduleBlock]() {
        didSet {
            schedule.sort(by: { $0.timing.start < $1.timing.start })
            destinations = schedule.compactMap({ $0.destinations }).flatMap({$0})
        }
    }
    
    var destinations = [Destination]()
    var route = Route()
    var travelMode = TravelMode.driving
    
    // computed props
    
    var optionBlocks : [OptionBlock] {
        return schedule.filter({$0.self is OptionBlock.Type}).map({ $0 as! OptionBlock })
    }
    
    var duration : TimeInterval {
        var totalDuration = route.travelTime
        destinations.forEach({dest in
            totalDuration += dest.timing.duration
        })
        return totalDuration
    }
    
}

