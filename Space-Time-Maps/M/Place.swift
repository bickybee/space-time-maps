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

struct Coordinate {
    var lat, lon: Double
}

// Is a class not a struct to utilize by-reference passing instead by-value passing
class Place : NSObject {
    
    let name: String
    let coordinate: Coordinate
    let placeID: String
    var isInItinerary = false
    
    override var description : String {
        return "Place(name: \"\(name)\", coordinate: \(coordinate), placeID: \"\(placeID)\", isInItinerary: \(isInItinerary))"
    }
    
    init(name: String, coordinate: Coordinate, placeID: String, isInItinerary: Bool) {
        self.name = name
        self.coordinate = coordinate
        self.placeID = placeID
        self.isInItinerary = isInItinerary
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.placeID == rhs.placeID
    }
    
}

// Dumb stuff for creating placeholders in empty collectionview sections...
extension Place {
    
    static func placeholder() -> Place {
        return Place(name: "PLACEHOLDER", coordinate: Coordinate(lat:0, lon:0), placeID: "", isInItinerary: false)
    }
    
    func isPlaceholder() -> Bool {
        return self == Place.placeholder()
    }
    
}


