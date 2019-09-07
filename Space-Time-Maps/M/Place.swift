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
    let timeSpent: TimeInterval
    
    override var description : String {
        return "Place(name: \"\(name)\", coordinate: \(coordinate), placeID: \"\(placeID)\""
    }
    
    init(name: String, coordinate: Coordinate, placeID: String, timeSpent: TimeInterval) {
        self.name = name
        self.coordinate = coordinate
        self.placeID = placeID
        self.color = ColorUtils.randomColor()
        self.timeSpent = timeSpent
    }
    
    convenience init(name: String, coordinate: Coordinate, placeID: String) {
        self.init(name: name, coordinate: coordinate, placeID: placeID, timeSpent: Place.defaultTimeSpent)
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.placeID == rhs.placeID
    }
    
}

class PlaceGroup {
    
    enum Kind : String {
        case asManyOf, oneOf, none
    }
    
    var name : String
    var places : [Place]
    var kind : PlaceGroup.Kind
    
    init(name: String, places: [Place], kind: PlaceGroup.Kind) {
        self.name = name
        self.places = places
        self.kind = kind
    }
    
    func copy() -> PlaceGroup {
        return PlaceGroup(name: self.name, places: self.places, kind: self.kind)
    }
    
}


