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
    var movingPlace : Place
    var originalIndex : Int
    var callback : ([Destination]?, Route?) -> ()
    
    static let scheduler = Scheduler()
    
    init(movingPlace place: Place, withIndex index: Int, inDestinations destinations: [Destination], travelMode: TravelMode, callback: @escaping ([Destination]?, Route?) -> ()) {
        self.movingPlace = place
        self.baseDestinations = destinations
        self.travelMode = travelMode
        self.callback = callback
        self.originalIndex = index
    }
    
    func moveDestination(toTime time: TimeInterval){
        
        let destination = Destination(place: movingPlace, startTime: time, constraints: Constraints())
        var modifiedDestinations = baseDestinations
        modifiedDestinations.append(destination)
        modifiedDestinations.sort(by: { $0.startTime <= $1.startTime })
        computeRoute(with: modifiedDestinations)
        
    }
    
    func removeDestination() {
        computeRoute(with: baseDestinations)
    }

    
    func computeRoute(with destinations: [Destination]) {
        if destinations.count <= 1 {
            callback(destinations, [])
        } else {
            ItineraryEditingSession.scheduler.schedule(destinations: destinations, travelMode: travelMode, callback: callback)
        }
    }

}
