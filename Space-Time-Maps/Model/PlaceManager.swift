//
//  PlaceManager.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-16.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GooglePlaces

class PlaceManager : NSObject {
    
    var places = [Place]()
    
    init(withStarterPlaces: Bool) {
        super.init()
        if (withStarterPlaces) {
            print("Filling with default starter data")
            self.add(Place("Bahen Centre", "ChIJV8llUcc0K4gRe7a0R0E4WWQ", 43.659642599999991, -79.397667599999991))
            self.add(Place("Casa Loma", "ChIJs6Elz500K4gRT1jWAsHIfGE", 43.67803709999999, -79.409443899999999))
            self.add(Place("Christie Pits Park", "ChIJ8f_In4s0K4gRRK-KutieqXA", 43.664588799999997, -79.420680899999994))
        }
    }
    
    func add(_ place: Place) {
        self.places.append(place)
    }
    
    func insert(_ newPlace: Place, at index: Int) {
        if index <= places.count {
            places.insert(newPlace, at: index)
        }
    }
    
    func remove(at index: Int) {
        if index < places.count {
            places.remove(at: index)
        }
    }
    
    func remove(name: String) {
        if let index = self.places.index(where: { $0.name == name}) {
            self.places.remove(at: index)
        }
    }
    
    func getPlace(at index: Int) -> Place? {
        if places.indices.contains(index) {
            return places[index]
        }
        return nil
    }
    
    func placeAtCoordinate(_ coordinate: Coordinate) -> Place? {
        return self.places.first(where: {$0.coordinate == coordinate})
    }
    
    func getPlaces() -> [Place] {
        return self.places
    }
    
    func numPlaces() -> Int {
        return self.places.count
    }
}
