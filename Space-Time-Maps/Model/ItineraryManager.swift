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
    private var potentialRoutes = [Route?]()
    private let queryService : QueryService
    private var travelMode = TravelMode.driving
    
    init(_ qs : QueryService) {
        queryService = qs
    }
    
    func setRoute(_ newRoute: Route?) {
        if let theRoute = newRoute {
            route = theRoute
            NotificationCenter.default.post(name: .didUpdateItinerary, object: self)
        }
    }
    
    func getRoute() -> Route? {
        return route
    }
    
    func getRoutePolyline() -> String? {
        return route?.polyline
    }
    
    func getPlaceManager() -> PlaceManager {
        return placeManager
    }
    
    func setTravelMode(_ mode: TravelMode) {
        self.travelMode = mode
    }
    
    // Calculate new route with updated places
    func calculateItineraryUpdates() {
        let numPlaces = placeManager.numPlaces()
        if numPlaces < 2 {
            // No route, but still an update to the itinerary
            NotificationCenter.default.post(name: .didUpdateItinerary, object: self)
        } else {
            // Send route query with callback
            self.queryService.sendRouteQuery(places: placeManager.getPlaces(), travelMode: travelMode, callback: self.setRoute)
        }
    }
    
    func setPotentialRoute(_ route: Route, at index: Int) {
        print("setting a route permutation at \(index)")
        potentialRoutes[index] = route
    }
    
    func sendPotentialRoutesReadyNotification() {
        print("Got all route permutations")
    }
    
    // CURRENTLY ONLY FOR INSERTING NEW PLACE INTO ITINERARY
    // (need alternative func for moving a place that is already in the itinerary)
    func calculatePotentialRoutePermutations(for insertingPlace: Place) {
        
        // Place can be inserted at each existing index, or at end, or not at all
        let numPermutations = placeManager.numPlaces() + 2
        let numInsertionPermutations = numPermutations - 1
        
        potentialRoutes = [Route?](repeating: nil, count: numPermutations)
        var placePermutations = [[Place]]()
        
        // Generate all permutatiosn for inserting place
        for i in 0...numInsertionPermutations - 1 {
            var permutation = placeManager.getPlacesCopy()
            permutation.insert(insertingPlace, at: i)
            placePermutations.append(permutation)
        }
        
        // Add "permutation" for /not/ inserting the place to the end
        placePermutations.append(placeManager.getPlacesCopy())
        print("num permutations: \(placePermutations.count)")
        
        // Send off requests
        queryService.sendRoutePermutationQueries(placePermutations: placePermutations, travelMode: travelMode, perRouteCallback: setPotentialRoute(_:at:), batchCallback: sendPotentialRoutesReadyNotification)
        
    }
    
}

extension Notification.Name {
    static let didUpdateItinerary = Notification.Name("didUpdateItinerary")
}

