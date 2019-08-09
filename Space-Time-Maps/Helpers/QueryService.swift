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
    
    // Send REST API query given an (ordered) list of places and a travel mode, callback with Route
    func sendRouteQuery(places: [Place], travelMode: TravelMode, callback: @escaping (Route) -> ()) {
        
        guard let url = routeQueryURLFrom(places: places, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            guard let route = self.dataToRoute(data) else { return }
            callback(route)
        }
    }
    
    func getRouteFor(destinations: [Destination], travelMode: TravelMode, callback: @escaping (Route) -> ()) {
        
        let orderedDestinations = destinations.sorted(by: { $0.startTime < $1.startTime })
        var legs = [Leg]()
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.notify(queue: .main) {
            let route = Route(polyline: "", duration: 0, legs: legs)
            callback(route)
        }
        
        for i in 0 ..< orderedDestinations.count - 1 {
            dispatchGroup.enter()
            
            let start = orderedDestinations[i]
            let end = orderedDestinations[i+1]
            getLegFor(start: start, end: end, travelMode: travelMode) {leg in
                legs.append(leg)
                dispatchGroup.leave()
            }
    
        }
        
        
    }
    
    func getLegFor(start: Destination, end: Destination, travelMode: TravelMode, callback: @escaping (Leg) -> ()) {
        
        guard let url = queryURLFor(start: start, end: end, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            guard let leg = self.dataToLeg(data) else { return }
            callback(leg)
        }
        
    }
    
    // Unwrap JSON data to Route object
    func dataToLeg(_ data: Data) -> Leg? {
        
        // Attempt to decode JSON object into RouteResponseObject
        let decoder = JSONDecoder()
        guard let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data) else { return nil }
        
        // Parse out data into Route object
        let firstRouteOption = routeResponseObject.routes[0]
        let polyline = firstRouteOption.overviewPolyline.points
        let duration = firstRouteOption.legs[0].duration.value
        let leg = Leg(polyline: polyline, duration: duration)
        
        return leg
        
    }
    
    func queryURLFor(start: Destination, end: Destination, travelMode: TravelMode) -> URL? {
        
        guard var urlComponents = URLComponents(string: gmapsDirectionsURLString) else { return nil }
        
        let startingID = start.place.placeID
        let endingID = end.place.placeID
        let departureTime = start.absoluteStartTime.timeIntervalSince1970
        
        urlComponents.queryItems = [
            URLQueryItem(name:"origin", value:"place_id:\(startingID)"),
            URLQueryItem(name:"destination", value:"place_id:\(endingID)"),
            URLQueryItem(name:"mode", value: travelMode.rawValue),
            URLQueryItem(name: "departure_time", value: "\(departureTime)"),
            URLQueryItem(name:"key", value:"\(self.apiKey)")
        ]
        
        return urlComponents.url
        
    }
    
    func sendRouteQuery(destinations: [Destination], travelMode: TravelMode, callback: @escaping (Route) -> ()) {
        
        guard let url = routeQueryURLFrom(destinations: destinations, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            guard let route = self.dataToRoute(data) else { return }
            callback(route)
        }
    }
    
    
    // Unwrap JSON data to Route object
    func dataToRoute(_ data: Data) -> Route? {
        
        // Attempt to decode JSON object into RouteResponseObject
        let decoder = JSONDecoder()
        guard let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data) else { return nil }
        
        // Parse out data into Route object
        let firstRoute = routeResponseObject.routes[0]
        let line = firstRoute.overviewPolyline.points
        let legs = firstRoute.legs.map { Leg(polyline: "", duration: $0.duration.value) }
        var totalDuration = 0
        for leg in legs {
            totalDuration += leg.duration
        }
        let route = Route(polyline: line, duration: totalDuration, legs: legs)
        return route
        
    }
    
    // Run some query, return data to a callback
    func runQuery(url: URL, callback: @escaping (Data) -> ()) {
        
        // Set up data task
        let dataTask = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("ERROR")
                print(error.localizedDescription)
            } else if let data = data {
                print("SUCCESS")
                DispatchQueue.main.sync { // sync or async?
                    callback(data)
                }
            }
        }
        
        // Run data task
        dataTask.resume()
    }
    
    // Returns directions query URL given a list of destinations
    func routeQueryURLFrom(destinations: [Destination], travelMode: TravelMode) -> URL? {
        
        
        
        return nil
    }
    
    // Returns directions query URL given a list of places
    func routeQueryURLFrom(places: [Place], travelMode: TravelMode) -> URL? {
        
        // Zero or one places: no route to be created
        guard places.count >= 2 else { return nil }
        
        // 2 or more places, we can make a route query
        let startingID = places.first!.placeID
        let endingID = places.last!.placeID
        var enrouteIDs : [String]?
        if (places.count >= 3) {
             enrouteIDs = Array(places[1 ... places.count - 2]).map( { $0.placeID } )
        }
        
        return routeQueryURLFrom(startingID: startingID, endingID: endingID, enrouteIDs: enrouteIDs, travelMode: travelMode)
    }
    
    // Returns directions query URL given places organized by starting, ending, enroute
    func routeQueryURLFrom(startingID: String, endingID: String, enrouteIDs: [String]?, travelMode: TravelMode) -> URL? {
        
        guard var urlComponents = URLComponents(string: gmapsDirectionsURLString) else { return nil }
            
        urlComponents.queryItems = [
            URLQueryItem(name:"origin", value:"place_id:\(startingID)"),
            URLQueryItem(name:"destination", value:"place_id:\(endingID)"),
            URLQueryItem(name:"mode", value: travelMode.rawValue),
            URLQueryItem(name:"key", value:"\(self.apiKey)")
        ]
        
        if let enrouteIDs = enrouteIDs {
            var enrouteString = ""
            for placeID in enrouteIDs {
                enrouteString += "|place_id:" + placeID
            }
            urlComponents.queryItems?.append(
                URLQueryItem(name:"waypoints", value:"optimize:true\(enrouteString)")
            )
        }
        
        return urlComponents.url

    }

    func getRoute(_ fromPlaceID: String, _ toPlaceID: String, _ waypointIDs: [String]?, _ travelMode: TravelMode, _ callback: @escaping RouteQueryResultHandler) {
        
        if var urlComponents = URLComponents(string: gmapsDirectionsURLString) {
            
            urlComponents.queryItems = [
                URLQueryItem(name:"origin", value:"place_id:\(fromPlaceID)"),
                URLQueryItem(name:"destination", value:"place_id:\(toPlaceID)"),
                URLQueryItem(name:"mode", value: travelMode.rawValue),
                URLQueryItem(name:"key", value:"\(self.apiKey)")
            ]
            
            if let waypointIDs = waypointIDs {
                var waypointString = ""
                for placeID in waypointIDs {
                    waypointString += "|place_id:" + placeID
                }
                urlComponents.queryItems?.append(
                    URLQueryItem(name:"waypoints", value:"optimize:true\(waypointString)")
                )
            }
            
            guard let url = urlComponents.url else { return }
            print(urlComponents.url!)
            
            let dataTask = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("ERROR")
                    print(error.localizedDescription)
                } else if let data = data {
                    print("SUCCESS")
                    let decoder = JSONDecoder()
                    if let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data) {
                        let firstRoute = routeResponseObject.routes[0]
                        let line = firstRoute.overviewPolyline.points
                        let legs = firstRoute.legs.map { Leg(polyline: "", duration: $0.duration.value) }
                        var totalDuration = 0
                        for leg in legs {
                            totalDuration += leg.duration
                        }
                        let route = Route(polyline: line, duration: totalDuration, legs: legs)
                        print("RESPONSE ?")
                        DispatchQueue.main.async {
                            callback(route)
                        }
                    }
                }
            }
            dataTask.resume()
        }
        
    }
    

    
}

