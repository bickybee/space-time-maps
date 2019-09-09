//
//  Scheduler.swift
//  Space-Time-Maps
//
//  Created by Vicky on 17/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

class Scheduler {
    
    // Here is where we determine exactly which places + timings get sent to Google Directions API
    // Using distance matrix API for batch calculations
    
    let qs = QueryService()
    var legCache = [String : LegData]()
    
    // Get a route for the given list of blocks
    func schedule(blocks: [ScheduleBlock], travelMode: TravelMode, callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {

        // Make a copy, in case the original block list gets modified during this process
//        let inputBlocks = blocks.map{ $0.copy() }
        
        let scheduledBlocks = scheduleBlocks(blocks, travelMode: travelMode)
        let route = routeFromBlocks(scheduledBlocks, travelMode: travelMode)
        if route != nil {
            let optionBlocks = scheduledBlocks.compactMap({ $0 as? OptionBlock })
            optionBlocks.forEach({ evenlyDisperseBlock($0, in: route!) })
        }
        
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
            else if var optionBlock = block as? OptionBlock {
                
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
                            optionBlock.optionIndex = option
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

    
    func findBestOption(_ optionBlock: OptionBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
        
        if let oneOf = optionBlock as? OneOfBlock {
            findBestOption(oneOf, before: before, after: after, travelMode: travelMode, callback: callback)
        } else if let asManyOf = optionBlock as? AsManyOfBlock {
            findBestOption(asManyOf, before: before, after: after, travelMode: travelMode, callback: callback)
        } else {
            callback(nil)
        }
        
    }
    
    // also /creates/ the options???
    func findBestOption(_ oneOfBlock: OneOfBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
        
        // If it's an isolated group, just pick the first option
        guard !(before == nil && after == nil) else {
            callback(nil)
            return
        }
        
        getMatrixFor(oneOfBlock, before: before, after: after, travelMode: travelMode) { matrix in
            guard let matrix = matrix else {
                callback(nil)
                return
            }
            
            let index = self.indexOfBestOption(matrix)
            callback(index)
        }
    }
    
    
    func findBestOption(_ asManyOfBlock: AsManyOfBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
        
        let places = asManyOfBlock.placeGroup.places
        let indices = [Int](0...places.count - 1)
        var permutations = [[Int]]()
        Utils.permute(indices, indices.count - 1, &permutations)
        
        getMatrixFor(asManyOfBlock, before: before, after: after, travelMode: travelMode) { matrix in
            guard let matrix = matrix else {
                callback(nil)
                return
            }
            
            let startTime = asManyOfBlock.timing.start
            let (index, optionTimings) = self.computeOptions(matrix, permutations)
            let options = self.permutationsToDestinations(permutations, optionTimings, places, startTime)
            asManyOfBlock.permutations = options
            callback(index)
        }
        
    }
    
    func permutationsToDestinations(_ permutations: [[Int]], _ timings: [[TimeInterval]], _ places: [Place], _ startTime: TimeInterval) -> [[Destination]] {
        
        var options = [[Destination]]()
        
        for (i, perm) in permutations.enumerated() {
            var destinations = [Destination]()
            var time = startTime
            
            for (j, placeIndex) in perm.enumerated() {
                time += timings[i][j]
                destinations.append(Destination(place: places[placeIndex], timing: Timing(start: time, duration: TimeInterval.from(minutes: 30))))
                time += TimeInterval.from(minutes: 30)
            }
            
            options.append(destinations)
        }
        
        return options
    }
    
    func getMatrixFor(_ optionBlock: OptionBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback: @escaping (TimeMatrix?) -> ()) {
        
        // Prepare matrix to be sent to Google Distance Matrix API
        var origins = [Place]()
        origins.append(contentsOf: optionBlock.placeGroup.places)
        if let before = before { origins.append(before.place) }
        
        var destinations = [Place]()
        destinations.append(contentsOf: optionBlock.placeGroup.places)
        if let after = after { destinations.append(after.place) }
        
        // Get matrix
        self.qs.getMatrixFor(origins: origins, destinations: destinations, travelMode: travelMode) { matrix in
            callback(matrix)
        }
    }
    
    func computeOptions(_ matrix: TimeMatrix, _ permutations: [[Int]]) -> (Int, [[TimeInterval]]) {
        
        var timings = [[TimeInterval]]()
        let last = matrix.endIndex - 1
        
        for permutation in permutations {
            var optionTiming = [TimeInterval]()
            
            // A -> B0
            optionTiming.append(matrix[permutation.first!][last])
            // B0 -> B(n-1)
            for j in 0 ... permutation.count - 2 {
                let from = permutation[j + 1]
                let to = permutation[j]
                optionTiming.append(matrix[to][from])
            }
            
            // Bn -> C
            optionTiming.append(matrix[last][permutation.last!])
            timings.append(optionTiming)
        }
        
        let scores = timings.map( { $0.reduce(0, +) } )
        let minScore = scores.min()
        let index = scores.firstIndex(of: minScore!)
        return (index!, timings)
        
    }
    
    // Determine best option ==> involves east travel time!
    func indexOfBestOption(_ matrix: TimeMatrix) -> Int {
        
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
    
    func routeFromBlocks(_ blocks: [ScheduleBlock], travelMode: TravelMode) -> Route? {
        
        // First get destinations out of all blocks...
        let destinations = blocks.compactMap({ $0.destinations }).flatMap({ $0 })
        return routeFromDestinations(destinations, travelMode: travelMode)
        
    }
    
    func hashForLeg(start: Destination, end: Destination) -> String {
        return start.place.placeID + end.place.placeID
    }
    
    // Access API to get a route
    func routeFromDestinations(_ destinations: [Destination], travelMode: TravelMode) -> Route? {
        
        let route = Route()
        let dispatchGroup = DispatchGroup()
        guard destinations.count > 1 else { return route }
        
        for i in 0 ... destinations.count - 2 {
            
            let start = destinations[i]
            let end = destinations[i + 1]
            let timing = Timing(start: start.timing.end, end: end.timing.start)
            let hash = hashForLeg(start: start, end: end)
            
            if let cached = legCache[hash] {
                let leg = Leg(data: cached, timing: timing)
                route.add(leg)
                
            }
            else {
                dispatchGroup.enter()
                self.qs.getLegDataFor(start: start, end: end, travelMode: travelMode) { legData in
                    
                    if let legData = legData {
                        let leg = Leg(data: legData, timing: timing)
                        route.add(leg)
                        self.legCache[hash] = legData
                    }
                    
                    dispatchGroup.leave()
                    
                }
            }
        }
        
        // Wait for all legs of route to be determined, then return
        dispatchGroup.wait()
        return route
    }

    func evenlyDisperseBlock(_ optionBlock: OptionBlock, in route: Route) {
        
        guard var destinations = optionBlock.destinations, destinations.count >= 2 else { return }
 
        let timeBounds = timeBoundsOf(destinations, within: optionBlock.timing, in: route)
        evenlyDisperseDestinations(destinations, within: timeBounds, in: route)
        
    }
    
    func timeBoundsOf(_ destinations : [Destination], within timing: Timing, in route: Route) -> Timing {
        
        let firstPlace = destinations.first!.place
        let lastPlace = destinations.last!.place
        let enteringLeg = route.legEndingAt(firstPlace)
        let leavingLeg = route.legStartingAt(lastPlace)
        
        let minStartTime = enteringLeg != nil ? enteringLeg!.timing.start + enteringLeg!.travelTiming.duration : Double.infinity
        let maxEndTime = leavingLeg != nil ? leavingLeg!.timing.end - leavingLeg!.travelTiming.duration : -Double.infinity
        
        let startTime = max(minStartTime, timing.start)
        let endTime = min(maxEndTime, timing.end)
        
        return Timing(start: startTime, end: endTime)
    }
    
    func evenlyDisperseDestinations(_ destinations : [Destination], within timing: Timing, in route: Route) {
        
        var extraTime = timing.duration
        var legs = [Leg]()
        
        for (i, dest) in destinations.enumerated() {
            extraTime -= dest.timing.duration
            if i < (destinations.count - 1) {
                let leg = route.legStartingAt(dest.place)!
                legs.append(leg)
                extraTime -= leg.travelTiming.duration
            }
        }
        
        let timeBetweenDests = extraTime / Double((destinations.count - 1))
        for (i, leg) in legs.enumerated() {
            let legStartTime = destinations[i].timing.end
            let duration = timeBetweenDests
            leg.timing = Timing(start: legStartTime, duration: duration)
            
            let nextDestStartTime = leg.timing.end
            let nextDestDuration = destinations[i + 1].timing.duration
            let nextDest = destinations[i + 1]
            nextDest.timing = Timing(start: nextDestStartTime, duration: nextDestDuration)
            
        }
        
    }
    
}



