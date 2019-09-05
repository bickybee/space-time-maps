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
    
    // Get a route for the given list of blocks
    func schedule(blocks: [ScheduleBlock], travelMode: TravelMode, callback: @escaping ([ScheduleBlock], Route) -> ()) {

        // Make a copy, in case the original block list gets modified during this process
//        let inputBlocks = blocks.map{ $0.copy() }
        
        let scheduledBlocks = scheduleBlocks(blocks, travelMode: travelMode)
        let route = routeFromBlocks(scheduledBlocks, travelMode: travelMode)
        
        callback(scheduledBlocks, route)
    }
    
    // "Scheduling" here really means selecting an ideal OPTION for each Group Event
    func scheduleBlocks(_ blocks: [ScheduleBlock], travelMode: TravelMode) -> [ScheduleBlock] {
        
        var schedule = [ScheduleBlock]()
        let dispatchGroup = DispatchGroup()
        
        for (i, block) in blocks.enumerated() {
            
            // Destinations are scheduled as-is
            if let singleBlock = block as? SingleBlock {
                schedule.append(singleBlock)
            }
                
            // Groups must have their "best-option" calculated
            // TODO: handle different groups, ignore if "best-option" is already selected...
            else if let optionBlock = block as? OneOfBlock {
                
                // If this optionBlock already has an option selected, add to schedule
                if optionBlock.destinations != nil {
                    schedule.append(optionBlock)
                }
                // Otherwise, select an option!
                else {
                    dispatchGroup.enter()
                    // Option selection depends in previous and following events
                    // TODO: Handle if these are OptionBlocks too
                    let before = blocks[safe: i - 1] as? SingleBlock
                    let after = blocks[safe: i + 1] as? SingleBlock
                    
                    findBestOption(optionBlock, before:before, after: after, travelMode: travelMode) { option in
                        if let option = option {
                            optionBlock.selectedIndex = option
                            schedule.append(optionBlock)
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
    
    
    func findBestOption(_ oneOfBlock: OneOfBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
        
        // If it's an isolated group, just pick the first option
        guard !(before == nil && after == nil) else {
            callback(0)
            return
        }
        
        // Prepare matrix to be sent to Google Distance Matrix API
        var origins = [Destination]()
        origins.append(contentsOf: oneOfBlock.options)
        if let before = before { origins.append(before.destination) }
        
        var destinations = [Destination]()
        destinations.append(contentsOf: oneOfBlock.options)
        if let after = after { destinations.append(after.destination) }
        
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
    
    func routeFromBlocks(_ blocks: [ScheduleBlock], travelMode: TravelMode) -> Route {
        
        // First get destinations out of all blocks...
        let destinations = blocks.compactMap({ $0.destinations }).flatMap({ $0 })
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



