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

class Coordinate : NSObject {
    var lat, lon: Double!
    
    init(_ latitude: Double, _ longitude: Double) {
        super.init()
        self.lat = latitude
        self.lon = longitude
    }
    
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return (lhs.lat == rhs.lat) && (lhs.lon == rhs.lon)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Coordinate {
            return self == other
        } else {
            return false
        }
    }
}

final class Place : NSObject {
    
    let name: String
    let coordinate: Coordinate
    let placeID: String
    var inItinerary = false
    //    let address: String
    
    override var description: String {
        return "Place: name: \(name), coordinate: \(coordinate), placeID: \(placeID))"
    }
    
    init(_ name: String, _ placeID: String, _ latitude: Double, _ longitude: Double) {
        self.name = name
        self.placeID = placeID
        self.coordinate = Coordinate(latitude, longitude)
    }
    
    init(_ name: String, _ placeID: String, _ coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.placeID = placeID
        self.coordinate = Coordinate(coordinate.latitude, coordinate.longitude)
    }
    
    func setInItinerary(_ status : Bool) {
        inItinerary = status
    }
    
    func isInItinerary() -> Bool {
        return inItinerary
    }
    
    func copy() -> Place {
        return Place(name, placeID, coordinate.lat, coordinate.lon)
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return (lhs.name == rhs.name) && (lhs.placeID == rhs.placeID) && (lhs.coordinate == rhs.coordinate)
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? Place {
            return self == other
        } else {
            return false
        }
    }
    
}
