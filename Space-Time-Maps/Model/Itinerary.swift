//
//  Itinerary.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-19.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

class Itinerary {
    
    var enroutePlaces : [Place] = [Place]()
    var startingPlace : Place?
    var endingPlace : Place?
    
    func addEnroutePlace(_ newPlace : Place) {
        enroutePlaces.append(newPlace)
    }
    
    func insertEnroutePlace(_ newPlace : Place, at index: Int) {
        if enroutePlaces.indices.contains(index) {
            enroutePlaces.insert(newPlace, at: index)
        }
    }
    
    func setStartingPlace(_ place : Place) {
        startingPlace = place
    }
    
    func setEndingPlace(_ place : Place) {
        endingPlace = place
    }
    
}
