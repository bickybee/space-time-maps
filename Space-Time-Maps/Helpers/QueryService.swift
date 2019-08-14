//
//  QueryService.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-17.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps.GMSMutablePath

class QueryService {
    
    typealias RouteQueryResultHandler = (Route?) -> ()
    
    let session = URLSession(configuration: .default)
    let dispatchGroup = DispatchGroup()
    let gmapsDirectionsURLString = "https://maps.googleapis.com/maps/api/directions/json"
    var apiKey: String
    
    init() {
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = keys {
            let mapsKey = dict["mapsKey"] as? String
            apiKey = mapsKey!
        } else {
            apiKey = ""
        }
    }
    
    func runQuery(url: URL, callback: @escaping (Data) -> ()) {
        
        // Set up data task
        let dataTask = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("ERROR")
                print(error.localizedDescription)
            } else if let data = data {
                print("SUCCESS running query with response:")
                callback(data)
            }
        }
        
        // Run data task
        dataTask.resume()
    }
    
    // MARK: - Destination-based
    
    func getRouteFor(destinations: [Destination], travelMode: TravelMode, callback: @escaping (Route) -> ()) {
        
        var legs = [Leg]()
        let dispatchGroup = DispatchGroup()
        
        for i in 0 ..< destinations.count - 1 {
            dispatchGroup.enter()
            
            let start = destinations[i]
            let end = destinations[i+1]
            getLegFor(start: start, end: end, travelMode: travelMode) { leg in
                if let leg = leg {
                    legs.append(leg)
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.wait()
        
        DispatchQueue.main.async {
            let route = Route(legs: legs)
            callback(route)
        }
        
    }
    
    func getLegFor(start: Destination, end: Destination, travelMode: TravelMode, callback: @escaping (Leg?) -> ()) {
        
        guard let url = queryURLFor(start: start, end: end, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            let leg = self.dataToLeg(data)
            callback(leg)
        }
        
    }
    
    func dataToLeg(_ data: Data) -> Leg? {
        
        // Attempt to decode JSON object into RouteResponseObject
        let decoder = JSONDecoder()
        var leg : Leg?
        if let errorResponseObject = try? decoder.decode(ErrorResponseObject.self, from: data) {
            print(errorResponseObject.errorMessage)
            leg = nil
        } else if let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data) {
            // Parse out data into Route object
            let firstRouteOption = routeResponseObject.routes[0]
            let polyline = firstRouteOption.overviewPolyline.points
            let duration = firstRouteOption.legs[0].duration.value
            leg = Leg(polyline: polyline, duration: duration)
        }
        return leg
        
    }
    
    func queryURLFor(start: Destination, end: Destination, travelMode: TravelMode) -> URL? {
        
        guard var urlComponents = URLComponents(string: gmapsDirectionsURLString) else { return nil }
        
        let startingID = start.place.placeID
        let endingID = end.place.placeID
//        let departureTime = Int(start.absoluteStartTime.timeIntervalSince1970) // ignoring for now!!!
        
        urlComponents.queryItems = [
            URLQueryItem(name:"origin", value:"place_id:\(startingID)"),
            URLQueryItem(name:"destination", value:"place_id:\(endingID)"),
            URLQueryItem(name:"mode", value: travelMode.rawValue),
            URLQueryItem(name:"key", value:"\(self.apiKey)")
        ]
        
        return urlComponents.url
        
    }
    
    // MARK: - Place based (old)
//
//    // Send REST API query given an (ordered) list of places and a travel mode, callback with Route
//    func sendRouteQuery(places: [Place], travelMode: TravelMode, callback: @escaping (Route) -> ()) {
//
//        guard let url = routeQueryURLFrom(places: places, travelMode: travelMode) else { return }
//        runQuery(url: url) {data in
//            guard let route = self.dataToRoute(data) else { return }
//            callback(route)
//        }
//    }
//
//
//    // Unwrap JSON data to Route object
//    func dataToRoute(_ data: Data) -> Route? {
//
//        // Attempt to decode JSON object into RouteResponseObject
//        let decoder = JSONDecoder()
//        guard let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data) else { return nil }
//
//        // Parse out data into Route object
//        let firstRoute = routeResponseObject.routes[0]
//        let line = firstRoute.overviewPolyline.points
//        let legs = firstRoute.legs.map { Leg(polyline: "", duration: $0.duration.value) }
//        var totalDuration = 0
//        for leg in legs {
//            totalDuration += leg.duration
//        }
//        let route = Route(polyline: line, duration: totalDuration, legs: legs)
//        return route
//
//    }
//
//    // Returns directions query URL given a list of places
//    func routeQueryURLFrom(places: [Place], travelMode: TravelMode) -> URL? {
//
//        // Zero or one places: no route to be created
//        guard places.count >= 2 else { return nil }
//
//        // 2 or more places, we can make a route query
//        let startingID = places.first!.placeID
//        let endingID = places.last!.placeID
//        var enrouteIDs : [String]?
//        if (places.count >= 3) {
//             enrouteIDs = Array(places[1 ... places.count - 2]).map( { $0.placeID } )
//        }
//
//        return routeQueryURLFrom(startingID: startingID, endingID: endingID, enrouteIDs: enrouteIDs, travelMode: travelMode)
//    }
//
//    // Returns directions query URL given places organized by starting, ending, enroute
//    func routeQueryURLFrom(startingID: String, endingID: String, enrouteIDs: [String]?, travelMode: TravelMode) -> URL? {
//
//        guard var urlComponents = URLComponents(string: gmapsDirectionsURLString) else { return nil }
//
//        urlComponents.queryItems = [
//            URLQueryItem(name:"origin", value:"place_id:\(startingID)"),
//            URLQueryItem(name:"destination", value:"place_id:\(endingID)"),
//            URLQueryItem(name:"mode", value: travelMode.rawValue),
//            URLQueryItem(name:"key", value:"\(self.apiKey)")
//        ]
//
//        if let enrouteIDs = enrouteIDs {
//            var enrouteString = ""
//            for placeID in enrouteIDs {
//                enrouteString += "|place_id:" + placeID
//            }
//            urlComponents.queryItems?.append(
//                URLQueryItem(name:"waypoints", value:"optimize:true\(enrouteString)")
//            )
//        }
//
//        return urlComponents.url
//
//    }
    
}

