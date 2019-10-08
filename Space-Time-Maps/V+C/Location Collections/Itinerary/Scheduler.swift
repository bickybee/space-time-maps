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
    
    typealias Permutation<T> = [T] // Possibilities w/ varied orderings
    typealias Combination<T> = [T] // Possibilities w/ unvaried orderings
    
    let qs = QueryService()
    var legCache = [LegData]()
    
    
    // Returns blocks with destinations and timings set, associated scheduled route
    func schedule(blocks: [ScheduleBlock], changedOrder: Bool, travelMode: TravelMode, callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {

        // Make a copy, in case the original block list gets modified during this process
//        let inputBlocks = blocks.map{ $0.copy() }
        
        let scheduledBlocks = scheduleBlocks(blocks, changedOrder: changedOrder, travelMode: travelMode)
        let route = routeFromBlocks(scheduledBlocks, travelMode: travelMode)
        if route != nil {
            let optionBlocks = scheduledBlocks.compactMap({ $0 as? OptionBlock })
            optionBlocks.forEach({ evenlyDisperseBlock($0, in: route!) })
        }
        
        callback(scheduledBlocks, route)
    }
    
    
    // Returns blocks with destinations and timings set
    func scheduleBlocks(_ blocks: [ScheduleBlock], changedOrder: Bool, travelMode: TravelMode) -> [ScheduleBlock] {
        
        var schedule = [ScheduleBlock]()
        
        var i = 0
        
        while (i < blocks.count) {
            
            let block = blocks[i]
            
            // Single block scheduled as-is
            if let singleBlock = block as? SingleBlock {
                schedule.append(singleBlock)
                i += 1
                
                continue
            }
                
            // Otherwise it's an option block, requiring further calculations
            // How many option blocks are there in a row? Will need to consider them all together.
            let range = rangeOfOptionBlockChain(in: blocks, startingAt: i)
            let optionBlocks : [OptionBlock] = Array(blocks[range]).map( { $0 as! OptionBlock } )
            
            // Do the options need to be recalculated?
            // If the order has changed, yes
            // If the order hasn't changed, but one or more of the blocks hasn't had its options calculated yet, also yes
            var allCalculatedAlready = true
            if (!changedOrder) {
                for o in optionBlocks {
                    if o.destinations == nil {
                        allCalculatedAlready = false
                        break
                    }
                }
            }
            
            if (!changedOrder && allCalculatedAlready) {
                
            }
            
            let mustRecalculateOptions = changedOrder || (!allCalculatedAlready)
            
            // If they're all calculated already, move along, no rescheduling needed.
            if !mustRecalculateOptions {
                schedule.append(contentsOf: optionBlocks)
            }
            
            // If even one of them is not yet scheduled, all need to be reconsidered.
            else {
                
                // Are there destinations leading into/out of this set of option blocks?
                let before = blocks[safe: i - 1] as? SingleBlock
                let after = blocks[safe: range.upperBound + 1] as? SingleBlock
                
                let dispatchGroup = DispatchGroup()
                dispatchGroup.enter()
                
                scheduleOptionBlocks(optionBlocks, before: before, after: after, travelMode: travelMode) {
                    schedule.append(contentsOf: optionBlocks)
                    dispatchGroup.leave()
                }
                
                dispatchGroup.wait()
            }

            // Continue past the option block group
            i =  range.upperBound + 1

        }
        
        return schedule
        
    }
    
    // Sets destinations and timings for option blocks
    func scheduleOptionBlocks(_ blocks: [OptionBlock], before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping () -> ()) {
        
        var allPlaces = blocks.flatMap( { $0.placeGroup.places } )
        
        if let beforePlace = before?.place {
            allPlaces.append(beforePlace)
        }
        
        if let afterPlace = after?.place {
            allPlaces.append(afterPlace)
        }
        
        // Time dict = timings between places (by placeID)
        qs.getTimeDictFor(origins: allPlaces, destinations: allPlaces, travelMode: travelMode) { dict in
            
            // Use time dict to get scores for all possible permutations of destinations in option blocks,
            // Find best permutation!
            guard let timeDict = dict else { callback(); return }
            
            // First set perms of asManyOf blocks lol TODO: put this somewhere where it makes more sense
            
            for b in blocks {
                if let asManyOf = b as? AsManyOfBlock {
                    asManyOf.setPermutationsUsing(timeDict)
                }
            }
            
            let optionCombinations = self.optionCombinationsFor(blocks)
            let placeIDCombinations = self.placeIDCombinationsFor(blocks, indexCombinations: optionCombinations)
            let scores = self.optionScores(placeIDCombinations, from: timeDict, before: before, after: after)
            let minScore = scores.min()
            let iMin = scores.firstIndex(of: minScore!)!
            let bestOption = optionCombinations[iMin] // Contains ideal option index for each block
            
            for i in blocks.indices {
                
                var block = blocks[i]
                if let asManyOf = block as? AsManyOfBlock {
                    self.scheduleOptionsForBlock(asManyOf, with: timeDict)
                }
                
                block.optionIndex = bestOption[i]
                
            }
            
            callback()
        }
        
    }


    // Returns option index combinations
    func optionCombinationsFor(_ blocks: [OptionBlock]) -> [Combination<Int>] {
        
        var output = [Combination<Int>]()
        let options = blocks.map( { Array(0 ... $0.optionCount - 1) } )
        Utils.combinations(options, &output, [], 0, options.count - 1)
        return output
        
    }
    
    // Returns combinations of permutations of places within option blocks
    // Combination because the ordering of the blocks don't change, but their destinations do.
    // Permutations because the destinations within the blocks can be reordered
    func placeIDCombinationsFor(_ blocks: [OptionBlock], indexCombinations: [Combination<Int>]) -> [Combination<Permutation<String>>] {
        var combinations = [Combination<Permutation<String>>]()
        for combo in indexCombinations {
            var c = Combination<Permutation<String>>()
            for (iBlock, iPermutation) in combo.enumerated() {
                c.append(blocks[iBlock].permutationPlaceIDs[iPermutation])
            }
            combinations.append(c)
        }
        
        return combinations
    }
    
    // Score = total time of all legs involved in potential route for all possibilities
    func optionScores(_ placeIDCombos: [Combination<Permutation<String>>], from timeDict: TimeDict, before: SingleBlock?, after: SingleBlock?) -> [Double] {
        var flatter = placeIDCombos.map( { $0.flatMap( {$0} ) } )
        
        if let beforePlaceID = before?.place.placeID {
            for i in flatter.indices {
                flatter[i].insert(beforePlaceID, at: 0)
            }
        }
        
        if let afterPlaceID = after?.place.placeID {
            for i in flatter.indices {
                flatter[i].append(afterPlaceID)
            }
        }
        
        var scores = [Double]()
        for c in flatter {
            var score : Double = 0
            for i in c.indices.dropLast() {
                let key = PlacePair(startID: c[i], endID: c[i+1])
                score += timeDict[key]!
            }
            scores.append(score)
        }
        return scores
    }

    // Returns range of consecutive option blocks
    func rangeOfOptionBlockChain(in blocks: [ScheduleBlock], startingAt startIndex: Int) -> ClosedRange<Int> {
        var endIndex : Int?
        var i = startIndex
        while (endIndex == nil) && (i < blocks.count - 1){
            if blocks[i + 1] is OptionBlock {
                i += 1
            } else {
                endIndex = i
            }
        }
        let range = startIndex ... (endIndex ?? blocks.count - 1)
        return range
    }
    
    // Handle all scheduling for all potential options for block
    func scheduleOptionsForBlock(_ block: AsManyOfBlock, with timings: TimeDict) {
        
        var options = [[Destination]]()
        
        for perm in block.permutations {
            var destinations = [Destination]()
            var time = block.timing.start
            
            for i in perm.indices {
                let place = block.placeGroup[perm[i]]
                destinations.append(Destination(place: place, timing: Timing(start: time, duration: TimeInterval.from(minutes: 30))))
                time += TimeInterval.from(minutes: 30)
                if (i != perm.indices.last) {
                    let nextPlace = block.placeGroup[perm[i + 1]]
                    time += timings[PlacePair(startID: place.placeID, endID: nextPlace.placeID)]!
                }
            }
            
            options.append(destinations)
        }
        
        block.options = options
    }
    
    // Spread destinations of selected option evenly in optionBlock
    func evenlyDisperseBlock(_ optionBlock: OptionBlock, in route: Route) {
        
        guard let destinations = optionBlock.destinations, destinations.count >= 2 else { return }
        
        let timeBounds = timeBoundsOf(destinations, within: optionBlock.timing, in: route)
        evenlyDisperseDestinations(destinations, within: timeBounds, in: route)
        
    }
    
    // Figure out the time bounds (might not necessarily be the option block timing, depends on entering/exiting leg timings)
    func timeBoundsOf(_ destinations : [Destination], within timing: Timing, in route: Route) -> Timing {
        
        let firstPlace = destinations.first!.place
        let lastPlace = destinations.last!.place
        
        var minStartTime = -Double.infinity
        var maxEndTime = Double.infinity
        
        if let enteringLeg = route.legEndingAt(firstPlace) {
            minStartTime = enteringLeg.timing.start + enteringLeg.travelTiming.duration
        }
        
        if let leavingLeg = route.legStartingAt(lastPlace) {
            maxEndTime = leavingLeg.timing.end - leavingLeg.travelTiming.duration
        }
        
        let startTime = max(minStartTime, timing.start)
        let endTime = min(maxEndTime, timing.end)
        
        return Timing(start: startTime, end: endTime)
    }
    
    func evenlyDisperse(_ destinations: [Destination], within timing: Timing, timeDict: TimeDict) {
        
    }
    
    
    func evenlyDisperseDestinations(_ destinations : [Destination], within timing: Timing, in route: Route) {
        
        var extraTime = timing.duration
        var legs = [Leg]()
        
        let firstDest = destinations[0]
        firstDest.timing.start = timing.start
        firstDest.timing.end = firstDest.timing.start + firstDest.timing.duration
        
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
    
    // MARK: - Route scheduling

    func routeFromBlocks(_ blocks: [ScheduleBlock], travelMode: TravelMode) -> Route? {
        
        // First get destinations out of all blocks...
        let destinations = blocks.compactMap({ $0.destinations }).flatMap({ $0 })
        return routeFromDestinations(destinations, travelMode: travelMode)
        
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
            
            if let cached = legCache.first(where: { $0.matches(start.place, end.place, travelMode) }) {
                let leg = Leg(data: cached, timing: timing)
                route.add(leg)
                
            }
            else {
                dispatchGroup.enter()
                self.qs.getLegDataFor(start: start, end: end, travelMode: travelMode) { legData in
                    
                    if let legData = legData {
                        let leg = Leg(data: legData, timing: timing)
                        route.add(leg)
                        self.legCache.append(legData)
                    }
                    
                    dispatchGroup.leave()
                    
                }
            }
        }
        
        // Wait for all legs of route to be determined, then return
        dispatchGroup.wait()
        return route
    }
    
}



