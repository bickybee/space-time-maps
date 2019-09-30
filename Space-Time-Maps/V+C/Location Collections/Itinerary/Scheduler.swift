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
    var legCache = [String : LegData]()
    
    
    // Returns blocks with destinations and timings set, associated scheduled route
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
    
    
    // Returns blocks with destinations and timings set
    func scheduleBlocks(_ blocks: [ScheduleBlock], travelMode: TravelMode) -> [ScheduleBlock] {
        
        var schedule = [ScheduleBlock]()
        
        var i = 0
        
        while (i < blocks.count) {
            
            let block = blocks[i]
            
            // Single block scheduled as-is
            if let singleBlock = block as? SingleBlock {
                schedule.append(singleBlock)
                i += 1
            }
                
            // Option blocks require furtuher calculations
            else if block is OptionBlock {
                
                // How many option blocks are there in a row? Will need to consider them all together.
                let range = rangeOfOptionBlockChain(in: blocks, startingAt: i)
                let optionBlocks : [OptionBlock] = Array(blocks[range]).map( { $0 as! OptionBlock } )
                var allScheduledAlready = true
                
                for o in optionBlocks {
                    if o.destinations == nil {
                        allScheduledAlready = false
                        break
                    }
                }
                
                // If they're all scheduled already, move along, no rescheduling needed.
                if allScheduledAlready {
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
                let key = c[i] + c[i+1]
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
                    time += timings[place.placeID + nextPlace.placeID]!
                }
            }
            
            options.append(destinations)
        }
        
        block.options = options
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
    
    //
    //    func computeOptions(_ matrix: TimeMatrix, _ permutations: [[Int]]) -> (Int, [[TimeInterval]]) {
    //
    //        var timings = [[TimeInterval]]()
    //        let last = matrix.endIndex - 1
    //
    //        for permutation in permutations {
    //            var optionTiming = [TimeInterval]()
    //
    //            // A -> B0
    //            optionTiming.append(matrix[permutation.first!][last])
    //            // B0 -> B(n-1)
    //            for j in 0 ... permutation.count - 2 {
    //                let from = permutation[j + 1]
    //                let to = permutation[j]
    //                optionTiming.append(matrix[to][from])
    //            }
    //
    //            // Bn -> C
    //            optionTiming.append(matrix[last][permutation.last!])
    //            timings.append(optionTiming)
    //        }
    //
    //        let scores = timings.map( { $0.reduce(0, +) } )
    //        let minScore = scores.min()
    //        let index = scores.firstIndex(of: minScore!)
    //        return (index!, timings)
    //
    //    }
    //
    //    // Determine best option ==> involves least travel time!
    //    func indexOfBestOption(_ matrix: TimeMatrix) -> Int {
    //
    //        let n = matrix.count - 1 // rows
    //        let m = matrix[0].count - 1 // cols
    //
    //        let numOptions = max(n, m)
    //        var scores = Array(repeating: 0.0, count: numOptions)
    //
    //        for i in 0...numOptions - 1 {
    //            scores[i] += m < n ? 0 : matrix[i][m]
    //            scores[i] += n < m ? 0 : matrix[n][i]
    //        }
    //
    //        let minScore = scores.min()
    //        let index = scores.firstIndex(of: minScore!)
    //        return index!
    //
    //    }
    //
//
//
//    func findBestOption(_ optionBlock: OptionBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
//
//        if let oneOf = optionBlock as? OneOfBlock {
//            findBestOption(oneOf, before: before, after: after, travelMode: travelMode, callback: callback)
//        } else if let asManyOf = optionBlock as? AsManyOfBlock {
//            findBestOption(asManyOf, before: before, after: after, travelMode: travelMode, callback: callback)
//        } else {
//            callback(nil)
//        }
//
//    }
//
//    // also /creates/ the options???
//    func findBestOption(_ oneOfBlock: OneOfBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
//
//        // If it's an isolated group, just pick the first option
//        guard !(before == nil && after == nil) else {
//            callback(nil)
//            return
//        }
//
//        getMatrixFor(oneOfBlock, before: before, after: after, travelMode: travelMode) { matrix in
//            guard let matrix = matrix else {
//                callback(nil)
//                return
//            }
//
//            let index = self.indexOfBestOption(matrix)
//            callback(index)
//        }
//    }
//
//
//    func findBestOption(_ asManyOfBlock: AsManyOfBlock, before: SingleBlock?, after: SingleBlock?, travelMode: TravelMode, callback:@escaping (Int?) -> ()) {
//
//        let places = asManyOfBlock.placeGroup.places
//        //        let placeIDs = places.map( { $0.placeID } )
//        //        var permutations = [[String]]()
//        let indices = Array(places.indices)
//        var permutations = [[Int]]()
//        Utils.permute(indices, indices.count - 1, &permutations)
//
//        getMatrixFor(asManyOfBlock, before: before, after: after, travelMode: travelMode) { matrix in
//            guard let matrix = matrix else {
//                callback(nil)
//                return
//            }
//
//            let startTime = asManyOfBlock.timing.start
//            let (index, optionTimings) = self.computeOptions(matrix, permutations)
//            let options = self.permutationsToDestinations(permutations, optionTimings, places, startTime)
//            asManyOfBlock.options = options
//            callback(index)
//        }
//
//    }
    
}



