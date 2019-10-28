//
//  Scheduler.swift
//  Space-Time-Maps
//
//  Created by Vicky on 17/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

class Scheduler {
    
    typealias Permutation<T> = [T] // Possibilities w/ varied orderings
    typealias Combination<T> = [T] // Possibilities w/ unvaried orderings
    
    private let qs = QueryService()
    private var legCache = [LegData]()
    private var timeDict = TimeDict()
    var travelMode : TravelMode = .driving
    
    // Reschedule everything!
    func reschedule(blocks: [ScheduleBlock], callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        
        guard blocks.count > 0 else {
            callback(blocks, Route()); return
        }
        
        let scheduledBlocks = scheduleBlocks(blocks)
        let route = routeFromBlocks(scheduledBlocks)
        
        callback(scheduledBlocks, route)
    }
    
    // Just changing positions of blocks, no re-ordering.
    func scheduleShift(blocks: [ScheduleBlock], callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        
        guard blocks.count > 0 else {
            callback(blocks, Route()); return
        }
        
        // Don't actually need to reschedule blocks, just the route!
        let route = routeFromBlocks(blocks)
        
        callback(blocks, route)
    }
    
    // Need to check if the pinch causes rescheduling changes
    func schedulePinch(of block: ScheduleBlock, in blocks: [ScheduleBlock], callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        
        guard blocks.count > 0 else {
            callback(blocks, Route()); return
        }
        
        var needsRescheduling = false
        
         // Only applicable if it's an asManyOf
        if let asManyOf = block as? AsManyOfBlock {
            if asManyOf.options.count == 0 {
                needsRescheduling = true
            } else {
                let originalPermLength = asManyOf.destinations!.count
                asManyOf.setPermutationsUsing(timeDict)
                let newPermLength = asManyOf.options[0].count //SO BAD!!!! FIXME
                scheduleOptionsForBlock(asManyOf, with: timeDict)
                
                needsRescheduling = originalPermLength != newPermLength
            }
        }
        
        if needsRescheduling {
            self.reschedule(blocks: blocks, callback: callback)
        } else {
            self.scheduleShift(blocks: blocks, callback: callback)
        }
        
    }
    
    // Changing option in optionBlock
    func scheduleOptionChange(of blockIndex: Int, toOption newIndex: Int, in blocks: [ScheduleBlock], callback: @escaping ([ScheduleBlock]?, Route?) -> ()) {
        
        guard var block = blocks[blockIndex] as? OptionBlock,
              let index = block.selectedOption else {
            callback(blocks, Route()); return
        }

        block.selectedOption = newIndex
        block.isFixed = true
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        reschedule(blocks: blocks) { blocks, route in
            callback(blocks, route)
            dispatchGroup.leave()
        }
        
        dispatchGroup.enter()
        
        scheduleShift(blocks: blocks) { blocks, route in
            callback(blocks, route)
            dispatchGroup.leave()
        }
        
        dispatchGroup.wait()
        
        block.isFixed = false
        
    }
    
    func updatePlaces(_ places: [Place]) {
        qs.getTimeDictFor(origins: places, destinations: places, travelMode: travelMode) { timeDict in
            guard let dict = timeDict else { return }
            self.timeDict = dict
        }
    }
    
    
}

// MARK: - Route scheduling
private extension Scheduler {
    
    
    func routeFromBlocks(_ blocks: [ScheduleBlock]) -> Route? {
        
        // First get destinations out of all blocks...
        let destinations = blocks.compactMap({ $0.destinations }).flatMap({ $0 })
        return routeFromDestinations(destinations)
        
    }
    
    // Access API to get a route
    func routeFromDestinations(_ destinations: [Destination]) -> Route? {
        
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

// MARK: - Private interal methods!!!

private extension Scheduler {
    
    
    // Returns blocks with destinations and timings set
    func scheduleBlocks(_ blocks: [ScheduleBlock]) -> [ScheduleBlock] {
        
//        if blocks.count == 1 {
//            let onlyBlock = blocks[0]
//            if onlyBlock is SingleBlock {
//                return blocks
//            }
//            let optionBlock = onlyBlock as! OptionBlock
//            if (optionBlock is OneOfBlock) && (optionBlock.selectedOption != nil) {
//                return blocks
//            }
//
//        }
        
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
            
            // Fixed option block scheduled as-is
            let optionBlock = block as! OptionBlock
            if optionBlock.isFixed {
                schedule.append(optionBlock)
                i += 1
                continue
                
            }
                
            // Otherwise requires further calculations
            // How many un-fixed option blocks are there in a row? Will need to consider them all together.
            let range = rangeOfOptionBlockChain(in: blocks, startingAt: i)
            let optionBlocks : [OptionBlock] = Array(blocks[range]).map( { $0 as! OptionBlock } )
            
            // Are there destinations leading into/out of this set of option blocks?
            let before = blocks[safe: i - 1] as? SingleBlock
            let after = blocks[safe: range.upperBound + 1] as? SingleBlock
            
            // Async...
            let dispatchGroup = DispatchGroup()
            dispatchGroup.enter()
            
            scheduleOptionBlocks(optionBlocks, before: before, after: after) { blocks in
                schedule.append(contentsOf: optionBlocks)
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
            
            // Continue past the option block group
            i =  range.upperBound + 1

        }
        
        return schedule
        
    }
    
    // Sets destinations and timings for option blocks
    func scheduleOptionBlocks(_ blocks: [OptionBlock], before: SingleBlock?, after: SingleBlock?, callback: @escaping ([OptionBlock]) -> ()) {
        
        var allPlaces = blocks.flatMap( { $0.placeGroup.places } )
        
        if let beforePlace = before?.place {
            allPlaces.append(beforePlace)
        }
        
        if let afterPlace = after?.place {
            allPlaces.append(afterPlace)
        }
        

        // First set perms of asManyOf blocks lol TODO: put this somewhere where it makes more sense
        for b in blocks {
            if let asManyOf = b as? AsManyOfBlock {
                asManyOf.setPermutationsUsing(timeDict)
            }
        }
        
        // Calculate the best combination of options
        let optionCombinations = self.optionCombinationsFor(blocks)
        let placeIDCombinations = self.placeIDCombinationsFor(blocks, indexCombinations: optionCombinations)
        let scores = self.optionScores(placeIDCombinations, from: timeDict, before: before, after: after)
        let minScore = scores.min()
        let iMin = scores.firstIndex(of: minScore!)!
        let bestOption = optionCombinations[iMin] // Contains ideal option index for each block
        
        // Select the option for each block
        for i in blocks.indices {
            
            var block = blocks[i]
            
            if let asManyOf = block as? AsManyOfBlock {
                self.scheduleOptionsForBlock(asManyOf, with: timeDict)
            }
            
            block.selectedOption = bestOption[i]
            
        }
        
        callback(blocks)
    }
    
    // Handle all scheduling for all potential options for block
    func scheduleOptionsForBlock(_ block: AsManyOfBlock, with timings: TimeDict) {
        
        var options = [[Destination]]()
        
        for perm in block.options {
            
            let places = perm.map( { block.placeGroup[$0] } )
            let destinations = evenlyDispersedDestinations(from: places, within: block.timing)
            options.append(destinations)
            
        }
        
        block.scheduledOptions = options
    }
    
    func evenlyDispersedDestinations(from places: [Place], within timing: Timing) -> [Destination] {
        
        var extraTime = timing.duration
        var destinations = [Destination]()
        
        for i in places.indices {
            let place = places[i]
            extraTime -= place.timeSpent
            if i < (places.count - 1) {
                let nextPlace = places[i + 1]
                let legTime = timeDict[PlacePair(startID: place.placeID, endID: nextPlace.placeID)]!
                extraTime -= legTime
            }
        }
        
        var time = timing.start
        let timeBetweenDests = extraTime / Double((places.count - 1))
        for (i, place) in places.enumerated() {
            let destTiming = Timing(start: time, duration: place.timeSpent)
            let dest = Destination(place: place, timing: destTiming)
            destinations.append(dest)
            
            time = destTiming.end + timeBetweenDests
        }
        
        return destinations
    }
    
    // Spread destinations of selected option evenly in optionBlock
    func evenlyDisperseBlock(_ optionBlock: OptionBlock, in route: Route) {
        
        guard let destinations = optionBlock.destinations, destinations.count >= 2 else { return }
        
        let timeBounds = timeBoundsOf(destinations, within: optionBlock.timing, in: route)
        evenlyDisperseDestinations(destinations, within: optionBlock.timing, in: route)
        
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
    
}

// Helper funcs
private extension Scheduler {
    
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
    
    // Returns option index combinations
    func optionCombinationsFor(_ blocks: [OptionBlock]) -> [Combination<Int>] {
        
        var output = [Combination<Int>]()
        let options = blocks.map( { Array<Int>(0 ... $0.options.count - 1) } )
        Combinatorics.combinations(options, &output, [], 0, options.count - 1)
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
                c.append(blocks[iBlock].optionPlaceIDs[iPermutation])
            }
            combinations.append(c)
        }
        
        return combinations
    }
    
    // Score = total time of all legs involved in potential route for all possibilities
    func optionScores(_ placeIDCombos: [Combination<Permutation<String>>], from timeDict: TimeDict, before: SingleBlock?, after: SingleBlock?) -> [Double] {
        var flattened = placeIDCombos.map( { $0.flatMap( {$0} ) } )
        
        if let beforePlaceID = before?.place.placeID {
            for i in flattened.indices {
                flattened[i].insert(beforePlaceID, at: 0)
            }
        }
        
        if let afterPlaceID = after?.place.placeID {
            for i in flattened.indices {
                flattened[i].append(afterPlaceID)
            }
        }
        
        var scores = [Double]()
        for c in flattened {
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
            if let ob = blocks[i + 1] as? OptionBlock {
                if !ob.isFixed {
                    i += 1
                } else {
                    endIndex = i
                }
                
            } else {
                endIndex = i
            }
        }
        let range = startIndex ... (endIndex ?? blocks.count - 1)
        return range
    }
    
    func permutationsToDestinations(_ permutations: [[Int]], _ timings: [[TimeInterval]], _ places: [Place], _ startTime: TimeInterval) -> [[Destination]] {
        
        var options = [[Destination]]()
        
        for (i, perm) in permutations.enumerated() {
            var destinations = [Destination]()
            var time = startTime
            
            for (j, placeIndex) in perm.enumerated() {
                time += timings[i][j]
                let place = places[placeIndex]
                destinations.append(Destination(place: place, timing: Timing(start: time, duration: place.timeSpent)))
                time += place.timeSpent
            }
            
            options.append(destinations)
        }
        
        return options
    }
    
}





