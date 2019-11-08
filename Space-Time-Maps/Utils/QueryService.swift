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

class QueryService {
        
    let session = URLSession(configuration: .default)
    let dispatchGroup = DispatchGroup()
    let gmapsDirectionsURLString = "https://maps.googleapis.com/maps/api/directions/json"
    let gmapsMatrixURLString = "https://maps.googleapis.com/maps/api/distancematrix/json"
    var apiKey: String
    
    var pingCount = 0
    
    init() {
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        if let dict = keys {
            let key = dict["apiKey"] as? String
            apiKey = key!
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
    
    func getTimeDictFor(origins: [Place], destinations: [Place], travelMode: TravelMode, callback: @escaping (TimeDict?) -> ()) {
        //dict [placeIDa + placeIDb] = time btwn them
        guard let url = queryURLFor(origins: origins, destinations: destinations, travelMode: travelMode) else { callback(nil); return }
        pingCount += 1
        print("pings to distance matrix API: \(pingCount)")
        callback(Utils.starterPlaceDict)
        runQuery(url: url) {data in
            let results = self.dataToTimeDict(data, origins, destinations)
            callback(results)
        }
    } 

    
    func getLegDataFor(start: Destination, end: Destination, travelMode: TravelMode, callback: @escaping (LegData?) -> ()) {
        
//        callback(nil)
        guard let url = queryURLFor(start: start, end: end, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            let leg =  self.dataToLeg(data, from: start, to: end, by: travelMode)
            callback(leg)
        }
        
    }
    
    func dataToLeg(_ data: Data, from start: Destination, to end: Destination, by travelMode: TravelMode) -> LegData? {
        
        // Attempt to decode JSON object into RouteResponseObject
        let decoder = JSONDecoder()
        var leg : LegData?
        if let errorResponseObject = try? decoder.decode(ErrorResponseObject.self, from: data) {
            print(errorResponseObject.errorMessage)
            leg = nil
        } else if let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data) {
            // Parse out data into Route object
            let firstRouteOption = routeResponseObject.routes[0]
            let polyline = firstRouteOption.overviewPolyline.points
            let duration = Double(firstRouteOption.legs[0].duration.value)
            leg = LegData(startPlace: start.place, endPlace: end.place, polyline: polyline, duration: TimeInterval(duration), travelMode: travelMode)
        }
        
        return leg
        
    }
    
    func dataToTimeDict(_ data: Data, _ origins: [Place], _ destinations: [Place]) -> TimeDict? {
        let decoder = JSONDecoder()
        var dict : TimeDict?
        if let errorResponseObject = try? decoder.decode(ErrorResponseObject.self, from: data) {
            print(errorResponseObject.errorMessage)
            dict = nil
        } else if let matrixResponseObject = try? decoder.decode(MatrixResponseObject.self, from: data) {
            // Parse out data into Route object
            dict = TimeDict()
            let originIDs = origins.map( { $0.placeID })
            let destIDs = destinations.map( { $0.placeID })
            for (i, row) in matrixResponseObject.rows.enumerated() {
                for (j, elem) in row.elements.enumerated() {
                    let key = PlacePair(startID: originIDs[i], endID: destIDs[j])
                    dict![key] = TimeInterval(elem.duration.value)
                }
            }
        }
        return dict
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
