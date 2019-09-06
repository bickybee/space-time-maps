//
//  QueryService.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-17.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps.GMSMutablePath
import ChameleonFramework

typealias TimeMatrix = [[TimeInterval]]

class QueryService {
        
    let session = URLSession(configuration: .default)
    let dispatchGroup = DispatchGroup()
    let gmapsDirectionsURLString = "https://maps.googleapis.com/maps/api/directions/json"
    let gmapsMatrixURLString = "https://maps.googleapis.com/maps/api/distancematrix/json"
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
    
    func getMatrixFor(origins: [Place], destinations: [Place], travelMode: TravelMode, callback: @escaping (TimeMatrix?) -> ()) {
        // matrix[row][col]
        guard let url = queryURLFor(origins: origins, destinations: destinations, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            let results = self.dataToMatrix(data)
            callback(results)
        }
    }
    
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
            let leg =  self.dataToLeg(data, from: start, to: end)
            callback(leg)
        }
        
    }
    
    func dataToLeg(_ data: Data, from start: Destination, to end: Destination) -> Leg? {
        
        // Attempt to decode JSON object into RouteResponseObject
        let timing = Timing(start: start.timing.end, end: end.timing.start)
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
            
            let startTime = timing.start + (timing.duration / 2.0) - (duration / 2.0)
            
            let travelTiming = Timing(start: startTime, duration: TimeInterval(duration))
            let colors = [start.place.color, end.place.color]
            leg = Leg(polyline: polyline, timing: timing, travelTiming: travelTiming, gradient: colors)
        }
        
        return leg
        
    }
    
    func dataToMatrix(_ data: Data) -> TimeMatrix? {
        let decoder = JSONDecoder()
        var matrix : TimeMatrix?
        if let errorResponseObject = try? decoder.decode(ErrorResponseObject.self, from: data) {
            print(errorResponseObject.errorMessage)
            matrix = nil
        } else if let matrixResponseObject = try? decoder.decode(MatrixResponseObject.self, from: data) {
            // Parse out data into Route object
            let rows = matrixResponseObject.originAddresses.count
            let cols = matrixResponseObject.destinationAddresses.count
            matrix = Array(repeating: Array(repeating: 0, count: cols), count: rows)
            for (i, row) in matrixResponseObject.rows.enumerated() {
                for (j, elem) in row.elements.enumerated() {
                    matrix![i][j] = TimeInterval(elem.duration.value)
                }
            }
        }
        return matrix
    }
    
    func queryURLFor(origins: [Place], destinations: [Place], travelMode: TravelMode) -> URL? {
        
        guard var urlComponents = URLComponents(string: gmapsMatrixURLString) else { return nil }
        
        let originsString = batchPlaceIDStringFrom(places: origins)
        let destinationsString = batchPlaceIDStringFrom(places: destinations)
        
        urlComponents.queryItems = [
            URLQueryItem(name:"origins", value:originsString),
            URLQueryItem(name:"destinations", value:destinationsString),
            URLQueryItem(name:"mode", value: travelMode.rawValue),
            URLQueryItem(name:"key", value: self.apiKey)
        ]
        
        return urlComponents.url
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
            URLQueryItem(name:"key", value: self.apiKey)
        ]
        
        return urlComponents.url
        
    }
    
    func batchPlaceIDStringFrom(places: [Place]) -> String {
        var str = ""
        for (index, place) in places.enumerated() {
            str += "place_id:" + place.placeID
            if index < places.endIndex {
                str += "|"
            }
        }
        return str
    }

}
