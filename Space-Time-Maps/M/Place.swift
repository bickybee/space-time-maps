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

class Place : NSObject {
    
    let name: String
    let coordinate: Coordinate
    let placeID: String
    
    override var description : String {
        return "Place(name: \"\(name)\", coordinate: \(coordinate), placeID: \"\(placeID)\""
    }
    
    init(name: String, coordinate: Coordinate, placeID: String) {
        self.name = name
        self.coordinate = coordinate
        self.placeID = placeID
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return lhs.placeID == rhs.placeID
    }
    
}


