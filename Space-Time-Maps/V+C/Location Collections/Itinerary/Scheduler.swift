//
//  Scheduler.swift
//  Space-Time-Maps
//
//  Created by Vicky on 17/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

class Scheduler : NSObject {
    
    // Here is where we determine exactly which places + timings get sent to Google Directions API
    // Using distance matrix API for batch calculations
    
    let qs = QueryService()
    
    // Get a route for the given list of events
    func schedule(events: [Event], travelMode: TravelMode, callback: @escaping ([Event], Route) -> ()) {

        // Make a copy, in case the original event list gets modified during this process
        let inputEvents = events.map{ $0.copy() }
        
        let scheduledEvents = scheduleEvents(inputEvents, travelMode: travelMode)
        let route = routeFromEvents(scheduledEvents, travelMode: travelMode)
        
        callback(scheduledEvents, route)
    }
    
    // "Scheduling" here really means selecting an ideal OPTION for each Group Event
    func scheduleEvents(_ events: [Event], travelMode: TravelMode) -> [Event] {
        
        var schedule = [Event]()
        let dispatchGroup = DispatchGroup()
        
        for (i, event) in events.enumerated() {
            
            // Destinations are scheduled as-is
            if let destination = event as? Destination {
                schedule.append(destination.copy())
            }
                
            // Groups must have their "best-option" calculated
            // TODO: handle different groups, ignore if "best-option" is already selected...
            else if var group = event as? OneOfGroup {
                
                if group.selectedDestination != nil {
                    schedule.append(group.copy())
                } else {
                    dispatchGroup.enter()
                    // Option selection depends in previous and following Event
                    // TODO: Handle if these are Groups (get their destination)
                    let before = events[safe: i - 1] as? Destination
                    let after = events[safe: i + 1] as? Destination
                    
                    findBestOption(group, before:before, after: after, travelMode: travelMode) { option in
                        if let option = option {
                            group.selectedIndex = option
                            schedule.append(group.copy())
                        }
                        
                        dispatchGroup.leave()
                    }
                    
                    // Do these synchronously by forcing waits between loop iterations...
                    dispatchGroup.wait()
                }
            }
        }
        
        return schedule
        
    }
    
    
    func findBestOption(_ group: OneOfGroup, before: Destination?, after: Destination?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
        
        // If it's an isolated group, just pick the first option
        guard !(before == nil && after == nil) else {
            callback(0)
            return
        }
        
        // Prepare matrix to be sent to Google Distance Matrix API
        var origins = [Destination]()
        origins.append(contentsOf: group.destinations)
        if let before = before { origins.append(before) }
        
        var destinations = [Destination]()
        destinations.append(contentsOf: group.destinations)
        if let after = after { destinations.append(after) }
        
        // Get matrix
        self.qs.getMatrixFor(origins: origins, destinations: destinations, travelMode: travelMode) { matrix in
            guard let matrix = matrix else {
                callback(nil)
                return
            }
            
            // Determine best option from matrix and return it
            let index = self.indexOfBestOption(matrix)
            callback(index)
        }
    }
    
    // Determine best option ==> involves east travel time!
    func indexOfBestOption(_ matrix: [[TimeInterval]]) -> Int {
        
        let n = matrix.count - 1 // rows
        let m = matrix[0].count - 1 // cols
        
        let numOptions = max(n, m)
        var scores = Array(repeating: 0.0, count: numOptions)
        
        for i in 0...numOptions - 1 {
            scores[i] += m < n ? 0 : matrix[i][m]
            scores[i] += n < m ? 0 : matrix[n][i]
        }
        
        let minScore = scores.min()
        let index = scores.firstIndex(of: minScore!)
        return index!
        
    }
    
    func routeFromEvents(_ events: [Event], travelMode: TravelMode) -> Route {
        
        // First get destinations out of all events...
        let destinations = events.compactMap({ (event) -> Destination? in
            if let destination = event as? Destination {
                return destination
            } else if let group = event as? OneOfGroup {
                return group.selectedDestination
            } else {
                return nil
            }
        })
        
        return routeFromDestinations(destinations, travelMode: travelMode)
        
    }
    
    // Access API to get a route
    func routeFromDestinations(_ destinations: [Destination], travelMode: TravelMode) -> Route {
        
        var route = Route()
        let dispatchGroup = DispatchGroup()
        
        for i in 0 ... destinations.count - 2 {
            
            dispatchGroup.enter()
            self.qs.getLegFor(start: destinations[i], end: destinations[i + 1], travelMode: travelMode) { leg in
                
                if let leg = leg {
                    route.append(leg)
                }
                
                dispatchGroup.leave()
                
            }
        }
        
        // Wait for all legs of route to be determined, then return
        dispatchGroup.wait()
        return route
    }
    
}



