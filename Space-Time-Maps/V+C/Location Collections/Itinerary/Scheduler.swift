//
//  Scheduler.swift
//  Space-Time-Maps
//
//  Created by Vicky on 17/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

// Here is where we determine exactly which places + timings get sent to Google Directions API
// Using distance matrix API for batch calculations

class Scheduler : NSObject {
    
    let qs = QueryService()
    
    func schedule(events: [Event], travelMode: TravelMode, callback: @escaping ([Destination], Route) -> ()) {

        let inputEvents = events //= events.map{ $0.copy() } // TODO
        
        let destinations = destinationsFromEvents(inputEvents, travelMode: travelMode)
        let route = routeFromDestinations(destinations, travelMode: travelMode)
        
        callback(destinations, route)
    }
    
    func routeFromDestinations(_ destinations: [Destination], travelMode: TravelMode) -> Route {
        
        var route = Route()
        let dispatchGroup = DispatchGroup()
        
        for i in 0 ... destinations.count - 2 {
            
            dispatchGroup.enter()
            self.qs.getLegFor(start: destinations[i], end: destinations[i + 1], travelMode: travelMode) { leg in
                if let leg = leg {
                    route.append(leg)
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.wait()
        return route
    }
    
    func destinationsFromEvents(_ events: [Event], travelMode: TravelMode) -> [Destination] {
        
        var destinations = [Destination]()
        let dispatchGroup = DispatchGroup()
        
        for (i, event) in events.enumerated() {
            if let destination = event as? Destination {
                destinations.append(destination)
            } else if let group = event as? OneOfBlock {
                dispatchGroup.enter()
                let before = events[safe: i - 1] as? Destination
                let after = events[safe: i + 1] as? Destination
                getBestOption(group, before:before, after: after, travelMode: travelMode) { option in
                    if let option = option {
                        destinations.append(option)
                    }
                    dispatchGroup.leave()
                }
                dispatchGroup.wait()
            }
        }
        
        return destinations
        
    }

    
    func getBestOption(_ group: OneOfBlock, before: Destination?, after: Destination?, travelMode: TravelMode, callback:@escaping (Destination?) -> ()) {
        
        guard !(before == nil && after == nil) else {
            callback(group.destinations.first)
            return
        }
        
        var origins = [Destination]()
        origins.append(contentsOf: group.destinations)
        if let before = before { origins.append(before) }
        
        var destinations = [Destination]()
        destinations.append(contentsOf: group.destinations)
        if let after = after { destinations.append(after) }
        
        self.qs.getMatrixFor(origins: origins, destinations: destinations, travelMode: travelMode) { matrix in
            guard let matrix = matrix else {
                callback(nil)
                return
            }
            
            let index = self.indexOfBestOption(matrix)
            let bestOption = group.destinations[index]
            callback(bestOption)
        }
    }
    
    func indexOfBestOption(_ matrix: [[TimeInterval]]) -> Int {
        
        let n = matrix.count - 1 // rows
        let m = matrix[0].count - 1 // cols
        
        let numOptions = max(n, m)
        var scores = Array(repeating: 0.0, count: numOptions)
        
        for i in 0...numOptions - 1 {
            scores[i] += m < n ? 0 : matrix[i][m]
            scores[i] += n < m ? 0 : matrix[n][i]
            print("score of \(i): \(scores[i])")
        }
        
        let minScore = scores.min()
        let index = scores.firstIndex(of: minScore!)
        return index!
    }
    
//    func schedule3(events: [Event], travelMode: TravelMode, callback: @escaping ([Event], Route) -> ()) {
//
//        let dispatchGroup = DispatchGroup()
//        var events = events.map( { return $0.copy() })
//        var legs = [Leg]()
//
//        for i in 0 ... events.count - 2 {
//            dispatchGroup.enter()
//            guard let destA = destinationFromEvent(events[i]),
//                let destB = destinationFromEvent(events[i + 1]) else { return }
//
//            self.qs.getLegFor(start: destA, end: destB, travelMode: travelMode) { leg in
//                if let leg = leg {
//                    legs.append(leg)
//                    dispatchGroup.leave()
//                }
//            }
//        }
//
//        dispatchGroup.wait()
//        callback(events, legs)
//    }
//
//    func destinationFromEvent(_ event: Event) -> Destination? {
//        var destination : Destination?
//        if let dest = event as? Destination {
//            destination = dest
//        } else if let group = event as? OneOfBlock {
//            guard let place = group.places[safe: 0] else { return nil }
//            destination = Destination(place: place, timing: group.timing, constraints: Constraints())
//        }
//        return destination
//    }
    
    
//    func scheduleEvents(seededAt index: Int, callback: () -> ()) {
//
//        let dispatchGroup = DispatchGroup()
//
//        let maxIndex = schedDests.count - 1
//        let minIndex = 0
//
//        // Propogating forward in time from first constrained event
//        if (index < maxIndex) {
//
//            dispatchGroup.enter()
//
//            scheduleEventsForward(seededAt: index) {
//                dispatchGroup.leave()
//            }
//        }
//
//        // Propogating backwards in time
//        if (index > minIndex) {
//
//            dispatchGroup.enter()
//
//            scheduleEventsBackward(seededAt: index) {
//                dispatchGroup.leave()
//            }
//        }
//
//        // Callback when it's all done
//        dispatchGroup.wait()
//        callback()
//
//    }
//
//    func scheduleEventsForward(seededAt index: Int, callback: @escaping () -> ()) {
//        var i = index
//        var destA = schedDests[index]
//        var destB = schedDests[index + 1]
//        var legCallback : ((Leg?) -> ())!
//
//        // Setup callback
//        legCallback = { leg in
//            var leg = leg!
//
//            i += 1
////            let minStartTime = destA.timing.start + destA.timing.duration + leg.travelTiming.duration
////            let nextDestA = destB.copy()
////            if nextDestA.timing.start < minStartTime {
////                nextDestA.timing.start = minStartTime
////            }
//
//            leg.timing = Timing(start: destA.timing.end, end: destB.timing.start)
//            self.schedLegs.append(leg)
//
////            self.schedDests[i] = nextDestA
//            self.schedDests[i] = destB.copy()
//
//            if i == self.schedDests.count - 1 {
//                callback()
//            } else {
//                destA = self.schedDests[i]
//                destB = self.schedDests[i + 1]
//                self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
//
//            }
//        }
//
//        // Begin recursive callback hell!
//        self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
//    }
//
//    func scheduleEventsBackward(seededAt index: Int, callback: @escaping () -> ()) {
//        var i = index
//        var destA = schedDests[index - 1]
//        var destB = schedDests[index]
//        var legCallback : ((Leg?) -> ())!
//
//        // Setup callback
//        legCallback = { leg in
//            var leg = leg!
//
//            let maxStartTime = destB.timing.start - destA.timing.duration - leg.travelTiming.duration
//            let nextDestA = destA.copy()
//            if nextDestA.timing.start > maxStartTime {
//                nextDestA.timing.start = maxStartTime
//            }
//
//            leg.timing = Timing(start: destA.timing.end, end: destB.timing.start)
//            self.schedLegs.append(leg)
//
//            self.schedDests[i - 1] = nextDestA
//            i -= 1
//
//            if i == 0 {
//                callback()
//            } else {
//                destA = self.schedDests[i - 1]
//                destB = self.schedDests[i]
//                self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
//
//            }
//        }
//
//        // Begin recursive callback hell!
//        self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
//    }
    
//    // Assume all are "fully constrained"
//    func schedule2(destinations: [Destination], travelMode: TravelMode, callback: @escaping ([Destination], Route) -> ()) {
//
//        // Member variables... (easy access within closures)
//        schedDests = destinations.map( { return $0.copy() })
//        schedLegs = [Leg]()
//
//        var i = 0
//        var destA = schedDests[0]
//        var destB = schedDests[1]
//        var legCallback : ((Leg?) -> ())!
//
//        // Setup callback
//        legCallback = { leg in
//
//            let leg = leg!
//            self.schedLegs.append(leg)
//
//            i += 1
//            let minStartTime = destA.timing.end + leg.timing.duration
//            let nextDestA = destB.copy()
//            if nextDestA.timing.start < minStartTime {
//                nextDestA.timing.start = minStartTime
//            }
//            self.schedDests[i] = nextDestA
//
//            if i == self.schedDests.count - 1 {
//                DispatchQueue.main.async {
//                    callback(self.schedDests, self.schedLegs)
//                }
//            } else {
//                destA = self.schedDests[i]
//                destB = self.schedDests[i + 1]
//                self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
//
//            }
//        }
//
//        // Begin recursive callback hell!
//        self.qs.getLegFor(start: destA, end: destB, travelMode: self.travelMode, callback: legCallback)
//
//    }
    
}



