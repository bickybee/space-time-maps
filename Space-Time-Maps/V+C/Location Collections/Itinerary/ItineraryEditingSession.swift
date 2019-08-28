//
//  DragSession.swift
//  Space-Time-Maps
//
//  Created by Vicky on 19/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import UIKit

class ItineraryEditingSession: NSObject {
    
    var travelMode : TravelMode
    var baseDestinations : [Destination]
    var movingDestination : Destination
    var originalIndex : Int
    var callback : ([Destination]?, Route?) -> ()
    
    static let scheduler = Scheduler()
    
    init(movingDestination destination: Destination, withIndex index: Int, inDestinations destinations: [Destination], travelMode: TravelMode, callback: @escaping ([Destination]?, Route?) -> ()) {
        destination.constraints.areEnabled = true
        self.movingDestination = destination
        self.baseDestinations = destinations
        self.travelMode = travelMode
        self.callback = callback
        self.originalIndex = index
    }
    
    func moveDestination(toTime time: TimeInterval){
                
        var modifiedDestinations = baseDestinations
        movingDestination.timing.start = time
        movingDestination.timing.end = time + movingDestination.timing.duration
        modifiedDestinations.append(movingDestination)
        modifiedDestinations.sort(by: { $0.timing.start <= $1.timing.start })
        computeRoute(with: modifiedDestinations)
        
    }
    
    func scaleDestinationDuration(with scale: Double) {
        let duration = movingDestination.timing.duration * scale
        let delta = duration - movingDestination.timing.duration
        movingDestination.timing.duration = duration
        movingDestination.timing.end += delta
        var modifiedDestinations = baseDestinations
        modifiedDestinations.append(movingDestination)
        computeRoute(with: modifiedDestinations)
    }
    
    func removeDestination() {
        computeRoute(with: baseDestinations)
    }
    
    func end() {
        movingDestination.constraints.areEnabled = false
        moveDestination(toTime: movingDestination.timing.start)
    }

    
    func computeRoute(with destinations: [Destination]) {
        if destinations.count <= 1 {
            callback(destinations, [])
        } else {
            ItineraryEditingSession.scheduler.schedule(destinations: destinations, travelMode: travelMode, callback: callback)
        }
    }

}
