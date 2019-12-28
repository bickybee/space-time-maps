//
//  TimeTickUtil.swift
//  Space-Time-Maps
//
//  Created by Vicky on 02/12/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps.GMSPath

class TimeTickService {
    
    var qs : QueryService
    
    init(_ queryService: QueryService) {
        self.qs = queryService
    }
    
    func getTimeTicksForLeg(_ leg: Leg, callback: @escaping([TimeTick]) -> ()) {
        let absoluteTimes = calculateIsochroneTimesFor(leg)
        let relativeTimes = relativeTimesFor(leg, fromIsochroneTimes: absoluteTimes)
        let dg = DispatchGroup()
        var ticksOnPath = [(TimeTick, Int)]()
        var legPath = GMSPath(fromEncodedPath: leg.polyline)!
        
        for (i, time) in relativeTimes.enumerated() {
            dg.enter()
            let lastTick = ticksOnPath.last ?? (TimeTick(time: 0, coordinate: leg.startPlace.coordinate), 0)
            qs.getIsochronesFor(origin: lastTick.0.coordinate, contourIntervals: [time], travelMode: leg.travelMode) { isochrones in
                
                guard let isochrone = isochrones?[safe: 0] else { dg.leave(); return }
                self.intersectionOfPath(legPath, startingFromIndex: lastTick.1, withIsochrone: isochrone) { intersection, index in
                    guard let intersection = intersection else { dg.leave(); return }
                    let timeTick = TimeTick(time: absoluteTimes[i], coordinate: intersection)
                    ticksOnPath.append((timeTick, index))
                    dg.leave()
                }
            }
            dg.wait()
        }
        callback(ticksOnPath.map { $0.0 })
        
    }
    
    func intersectionOfPath(_ legPath: GMSPath, startingFromIndex index: Int, withIsochrone isochrone: GMSPath, callback: @escaping(Coordinate?, Int) -> ()) {
    
        // google maps requires this happens on the main queue...
        var intersection : Coordinate?
        var i = UInt(index)
        
        while i < legPath.count() {
            let point = legPath.coordinate(at: i)
            if !GMSGeometryContainsLocation(point, isochrone, true) {
                // passed outside the border, so return the prev point as our "intersection"
                break
            }
            intersection = point
            i += 1
        }
        callback(intersection, Int(i))
    }
        
    func calculateIsochroneTimesFor(_ leg: Leg) -> [TimeInterval] {
        // calc time intervals
        var intervalTimes = [TimeInterval]()
        let first = Utils.ceilTime(leg.travelTiming.start)
        let last = Utils.floorTime(leg.travelTiming.end)
        var currentInterval = first
        while currentInterval <= last {
            intervalTimes.append(currentInterval)
            currentInterval += TimeInterval.from(minutes: 15)
        }
        return intervalTimes
    }

    func relativeTimesFor(_ leg: Leg, fromIsochroneTimes times: [TimeInterval]) -> [TimeInterval] {
        
        guard times.count > 0 else { return [] }
        
        let offset = leg.travelTiming.start
        var relativeTimes = [TimeInterval]()
        relativeTimes.append(times[0] - offset)
        for (i, t) in times.dropFirst().enumerated() {
            relativeTimes.append(t - (TimeInterval.from(minutes: 15) * Double(i)) - offset)
        }
        return relativeTimes
    }
    
}
