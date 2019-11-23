//
//  Route.swift
//  Space-Time-Maps
//
//  Created by Vicky on 09/09/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps

struct LegData {
    
    var startPlace : Place
    var endPlace : Place
    var polyline: String
    var duration: TimeInterval
    var travelMode : TravelMode
    
    func matches(_ start: Place, _ end: Place, _ travelMode: TravelMode) -> Bool {
        return (self.startPlace.placeID == start.placeID)
            && (self.endPlace.placeID == end.placeID)
            && (self.travelMode == travelMode)
    }
    
    static func == (lhs: LegData, rhs: LegData) -> Bool {
        return (lhs.startPlace.placeID == rhs.startPlace.placeID)
                && (lhs.endPlace.placeID == rhs.endPlace.placeID)
                && (lhs.travelMode == rhs.travelMode)
    }
    
}

class Leg : Schedulable {
    
    var startPlace : Place
    var endPlace : Place
    var polyline : String
    var coords : [Coordinate]
    var travelTiming : Timing
    var timing : Timing {
        didSet {
            travelTiming = Leg.computeTravelTiming(with: travelTiming.duration, within: timing)
        }
    }
    
    init (startPlace: Place, endPlace: Place, polyline: String, timing: Timing, travelTiming: Timing) {
        self.startPlace = startPlace
        self.endPlace = endPlace
        self.polyline = polyline
        self.timing = timing
        self.travelTiming = travelTiming
        self.coords = [Coordinate]()
        
        let path = GMSPath(fromEncodedPath: polyline)!
        for i in 0...path.count()-1 {
            let coord = path.coordinate(at: i)
            coords.append(Coordinate(lat: coord.latitude, lon: coord.longitude))
        }
    }
    
    convenience init (data: LegData, timing: Timing) {
        let travelTiming = Leg.computeTravelTiming(with: data.duration, within: timing)
        self.init(startPlace: data.startPlace, endPlace: data.endPlace, polyline: data.polyline, timing: timing, travelTiming: travelTiming)
    }
    
    private static func computeTravelTiming(with duration: TimeInterval, within availableTiming: Timing) -> Timing {
        // schedule leg in the middle of available timing
        let travelStartTime = availableTiming.start + (availableTiming.duration / 2.0) - (duration / 2.0)
        return Timing(start: travelStartTime, duration: duration)
    }
    
    
    func copy() -> Schedulable {
        return Leg(startPlace: self.startPlace, endPlace: self.endPlace, polyline: self.polyline, timing: self.timing, travelTiming: self.travelTiming)
    }
    
}

class Route : NSObject {
    
    var legs = [Leg]() {
        didSet {
            legs.sort(by: { $0.timing.start < $1.timing.start })
        }
    }
    
    var count : Int {
        return legs.count
    }
    
    var travelTime : TimeInterval {
        var totalTravelTime = TimeInterval(0)
        for l in legs {
            totalTravelTime += l.travelTiming.duration
        }
        return totalTravelTime
    }
    
    func add(_ leg: Leg) {
        legs.append(leg)
    }
    
    func legBetween(_ startPlace: Place, _ endPlace: Place) -> Leg? {
        return legs.first(where: { ($0.startPlace == startPlace) && ($0.endPlace == endPlace) })
    }
    
    func legStartingAt(_ place: Place) -> Leg? {
        return legs.first(where: { ($0.startPlace == place) })
    }
    
    func legEndingAt(_ place: Place) -> Leg? {
        return legs.first(where: { ($0.endPlace == place) })
    }

    
}


