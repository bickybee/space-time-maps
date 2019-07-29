//
//  ItineraryManager.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-23.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation

enum TravelMode : String {
    case driving, walking, bicycling, transit
}

// Itinerary = ordered list of places (place manager), route
// Manager => also handles queries and notifies observers of updates
class ItineraryManager : NSObject {
    
    private var placeManager = PlaceManager(withStarterPlaces: false)
    private var route : Route?
    private let queryService : QueryService
    private var travelMode = TravelMode.driving
    
    init(_ qs : QueryService) {
        queryService = qs
    }
    
    func addPlace(_ newPlace: Place) {
        placeManager.add(newPlace)
    }
    
    func insertPlace(_ newPlace: Place, at index: Int) {
        placeManager.insert(newPlace, at: index)
    }
    
    func removePlace(at index: Int) {
        placeManager.remove(at: index)
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
    
    func setRoute(_ newRoute: Route?) {
        if let theRoute = newRoute {
            route = theRoute
            NotificationCenter.default.post(name: .didUpdateItinerary, object: self)
        }
    }
    
    func getRoutePolyline() -> String? {
        return route?.polyline
    }
    
    func getRoute() -> Route? {
        return route
    }
    
    func numPlaces() -> Int {
        return placeManager.numPlaces()
    }
    
    func setTravelMode(_ mode: TravelMode) {
        self.travelMode = mode
    }
    
    // Calculate new route via query
    func calculateItineraryUpdates() {
        if let startingID = getStartingPlace()?.placeID {
            if let endingID = getEndingPlace()?.placeID {
                if let enrouteIDs = getEnroutePlaces()?.map ({$0.placeID}) {
                    // Route with waypoints
                    self.queryService.getRoute(startingID, endingID, enrouteIDs, travelMode, self.setRoute)
                } else {
                    // Route with only start and dest
                    self.queryService.getRoute(startingID, endingID, nil, travelMode, self.setRoute)
                }
            } else {
                // Just one place!
                NotificationCenter.default.post(name: .didUpdateItinerary, object: self)
            }
        }
    }
    
}

extension Notification.Name {
    static let didUpdateItinerary = Notification.Name("didUpdateItinerary")
}

