//
//  ItineraryManager.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-23.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

// Itinerary = ordered list of places (place manager), route
// Manager => also handles queries and notifies observers of updates
class ItineraryManager : NSObject {
    
    private var placeManager = PlaceManager(withStarterPlaces: false)
    private var route : String?
    private let queryService : QueryService
    
    init(_ qs : QueryService) {
        queryService = qs
    }
    
    func addPlace(_ newPlace: Place) {
        placeManager.add(newPlace)
        updateRoute()
    }
    
    func insertPlace(_ newPlace: Place, at index: Int) {
        placeManager.insert(newPlace, at: index)
        updateRoute()
    }
    
    func removePlace(at index: Int) {
        placeManager.remove(at: index)
        updateRoute()
    }
    
    func getPlace(at index: Int) -> Place? {
        return placeManager.getPlace(at: index)
    }
    
    func getPlaces() -> [Place] {
        return placeManager.getPlaces()
    }
    
    func hasStartingPlace() -> Bool {
        return placeManager.numPlaces() >= 1
    }
    
    func hasEndingPlace() -> Bool {
        return placeManager.numPlaces() >= 2
    }
    
    func hasEnroutePlaces() -> Bool {
        return placeManager.numPlaces() >= 3
    }
    
    func getStartingPlace() -> Place? {
        if hasStartingPlace() {
            return placeManager.getPlaces().first
        }
        return nil
    }
    
    func getEndingPlace() -> Place? {
        if hasEndingPlace() {
            return placeManager.getPlaces().last
        }
        return nil
    }
    
    func getEnroutePlaces() -> [Place]? {
        if hasEnroutePlaces() {
            return Array(placeManager.getPlaces()[1...placeManager.numPlaces()-2])
        }
        return nil
    }
    
    func setRoute(_ newRoute: String?) {
        if let theRoute = newRoute {
            route = theRoute
            NotificationCenter.default.post(name: .didUpdateRoute, object: self)
        }
    }
    
    func getRoute() -> String? {
        return route
    }
    
    func numPlaces() -> Int {
        return placeManager.numPlaces()
    }
    
    // Calculate new route via query
    func updateRoute() {
        if let startingID = getStartingPlace()?.placeID, let endingID = getEndingPlace()?.placeID {
            if let enrouteIDs = getEnroutePlaces()?.map ({$0.placeID}) {
                self.queryService.getWaypointRoute(startingID, endingID, enrouteIDs, self.setRoute)
            } else {
                self.queryService.getRoute(startingID, endingID, self.setRoute)
            }
        }
    }
    
}

extension Notification.Name {
    static let didUpdateRoute = Notification.Name("didUpdateRoute")
}

