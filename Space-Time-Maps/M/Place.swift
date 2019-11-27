//
//  Place.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-18.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps
import MobileCoreServices

// Simply a location

struct Coordinate {
    var lat, lon: Double
}

class Place : NSObject {
    
    static private let defaultTimeSpent = TimeInterval.from(hours: 1.0)
    
    let name: String
    let coordinate: Coordinate
    let placeID: String
    let color: UIColor
    var timeSpent: TimeInterval
    var itineraryIndex : Int?
    let openHours: Timing?
    var closedHours: [Timing]? {
        guard let open = self.openHours else { return nil }
        let closed1 = Timing(start: 0.0, end: open.start)
        let closed2 = Timing(start: open.end, end: TimeInterval.from(hours:24.5))
        return [closed1, closed2]
    }
    
    override var description : String {
        return "Place(name: \"\(name)\", coordinate: \(coordinate), placeID: \"\(placeID)\""
    }
    
    init(name: String, coordinate: Coordinate, placeID: String, timeSpent: TimeInterval, openHours: Timing?) {
        self.name = name
        self.coordinate = coordinate
        self.placeID = placeID
        self.color = ColorUtils.randomColor()
        self.timeSpent = timeSpent
        self.openHours = openHours
    }
    
    convenience init(name: String, coordinate: Coordinate, placeID: String) {
        self.init(name: name, coordinate: coordinate, placeID: placeID, timeSpent: Place.defaultTimeSpent, openHours: nil)
    }
    
    convenience init(name: String, coordinate: Coordinate, placeID: String, openHours: Timing?) {
        self.init(name: name, coordinate: coordinate, placeID: placeID, timeSpent: Place.defaultTimeSpent, openHours: openHours)
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.placeID == rhs.placeID
    }
    
}

class PlaceGroup {
    
    enum Kind : Int {
        case none = 0
        case oneOf = 1
        case asManyOf = 2
    }
    
    var name : String
    var places : [Place]
    var kind : PlaceGroup.Kind
    var count : Int {
        return places.count
    }
    
    subscript(_ index: Int) -> Place {
        return places[index]
    }
    
    init(name: String, places: [Place], kind: PlaceGroup.Kind) {
        self.name = name
        self.places = places
        self.kind = kind
    }
    
    func append(_ place: Place) {
        print(place)
        places.append(place)
    }
    
    func append(contentsOf arr: [Place]) {
        places.append(contentsOf: arr)
    }
    
    func remove(at index: Int) {
        places.remove(at: index)
    }
    
    func insert(_ place: Place, at index: Int) {
        places.insert(place, at: index)
    }
    
    func copy() -> PlaceGroup {
        return PlaceGroup(name: self.name, places: self.places, kind: self.kind)
    }
    
}

class Destination: NSObject, Schedulable {
    
    var place : Place
    var timing : Timing
    
    init(place: Place, timing: Timing) {
        self.place = place
        self.timing = timing
        
    }
    
    func copy() -> Schedulable {
        return Destination(place: self.place, timing: self.timing)
    }
    
    override var description: String {
        return "\(self.place.name), timing: \(self.timing)"
    }
}


