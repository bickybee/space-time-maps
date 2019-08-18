//
//  Scheduler.swift
//  Space-Time-Maps
//
//  Created by Vicky on 17/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation


class Scheduler : NSObject {
    
    let qs = QueryService()
    
    // Iteration 1) ASSUMING FIRST DEST IS FULLY CONSTRAINED... = starting point
    func schedule(destinations: [Destination], travelMode: TravelMode, callback: @escaping ([Destination], Route) -> ()) {
        
        guard destinations.count > 1 else { return }
        
        var legs = [Leg]()
        var scheduledDestinations = [Destination]()
        
        var i = 1
        var destA = destinations[i - 1]
        var destB = destinations[i]
        let maxIndex = destinations.count - 1
        
        scheduledDestinations.append(Destination(place: destA.place, startTime: destA.startTime))
        
        var legCallback : ((Leg?) -> ())!
        legCallback = { leg in
            let leg = leg! // FIX error handling
            
            legs.append(leg)
            let nextStartTime = destA.startTime + destA.duration + leg.duration
            let nextDestination = Destination(place: destB.place, startTime: nextStartTime)
            scheduledDestinations.append(nextDestination)
            
            i += 1
            if i <= maxIndex {
                destA = nextDestination
                destB = destinations[i]
                self.qs.getLegFor(start: destA, end: destB, travelMode: travelMode, callback: legCallback)
            } else {
                DispatchQueue.main.async {
                    callback(scheduledDestinations, legs)
                }
            }
        }
        
        qs.getLegFor(start: destA, end: destB, travelMode: travelMode, callback: legCallback)
        
    }
    
}
