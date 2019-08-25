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
            callback(legs)
        }
        
    }
    
    func getLegFor(start: Destination, end: Destination, travelMode: TravelMode, callback: @escaping (Leg?) -> ()) {
        
        guard let url = queryURLFor(start: start, end: end, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            let leg = self.dataToLeg(data, withDestinationTiming: Timing(start: start.timing.end, end: end.timing.start))
            callback(leg)
        }
        
    }
    
    func dataToLeg(_ data: Data, withDestinationTiming timing: Timing) -> Leg? {
        
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
            let duration = Double(firstRouteOption.legs[0].duration.value)
            
            let start = timing.start + (timing.duration / 2.0) - (duration / 2.0)
            
            let travelTiming = Timing(start: start, duration: TimeInterval(duration))
            leg = Leg(polyline: polyline, timing: timing, travelTiming: travelTiming)
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

}
