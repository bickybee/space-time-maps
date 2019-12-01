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
    let mapboxIsochroneURLString = "https://api.mapbox.com/isochrone/v1/mapbox/"
    var apiKey: String!
    var mapboxToken: String!
    
    var pingCount = 0
    
    init() {
        var keys: NSDictionary!
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        
        apiKey = keys["apiKey"] as? String
        mapboxToken = keys["mapboxToken"] as? String
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
        runQuery(url: url) {data in
            let results = self.dataToTimeDict(data, origins, destinations)
            callback(results)
        }
    }

    func getLegDataFor(start: Destination, end: Destination, travelMode: TravelMode, callback: @escaping (LegData?) -> ()) {

        guard let url = queryURLFor(start: start, end: end, travelMode: travelMode) else { return }
        runQuery(url: url) {data in
            let leg =  self.dataToLeg(data, from: start, to: end, by: travelMode)
//            let locations = self.locationsAlongLeg(leg!, ofDistance: 500)
//            self.getTimesFor(origins: [locations[0]], destinations: locations, travelMode: travelMode) { times in
//                let leg.timesOnPath =
//            }
            callback(leg)
        }

    }
    
//    func getIsochronesFor(origin: Place, )
    
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
    
    func dataToTimeAlongLeg(_ data: Data) -> [TimeInterval]? {
        let decoder = JSONDecoder()
        var timeAlongLeg : [TimeInterval]?
        if let errorResponseObject = try? decoder.decode(ErrorResponseObject.self, from: data) {
            print(errorResponseObject.errorMessage)
            timeAlongLeg = nil
        } else if let matrixResponseObject = try? decoder.decode(MatrixResponseObject.self, from: data) {
            // Parse out data
            timeAlongLeg = [TimeInterval]()
            for row in matrixResponseObject.rows{
                for elem in row.elements {
                    // Should be 1D!
                    timeAlongLeg!.append(TimeInterval(elem.duration.value))
                }
            }
        }
        
        return timeAlongLeg
    }
    
//    func locationsAlongLeg(_ leg: LegData, ofDistance metres: CLLocationDistance) -> [Coordinate] {
//        let path = GMSPath(fromEncodedPath: leg.polyline)!
//        var locations = [Coordinate]()
//        let coord0 = path.coordinate(at: 0)
//        var lastLoc = CLLocation(latitude: coord0.latitude, longitude: coord0.longitude)
//
//        for i in 1..<path.count() {
//            let coord = path.coordinate(at: UInt(i))
//            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
//            let diff = loc.distance(from: lastLoc)
//            if diff >= metres {
//                locations.append(Coordinate(lat: coord.latitude, lon: coord.longitude))
//                lastLoc = loc
//            }
//
//        }
//
//        print(locations.count)
//        print(path.length(of: .geodesic))
//
//        return locations
//    }
    
    func queryURLFor(origin: Place, contourIntervals: [TimeInterval], travelMode: TravelMode) -> URL? {

        // travelmodes are slightly diff for mapbox (bicycling != cycling)
        let profileString = (travelMode == .bicycling ? "cycling" : travelMode.rawValue) + "/"
        let coordString = "\(origin.coordinate.lon),\(origin.coordinate.lat)"
        let pathString = mapboxIsochroneURLString  + profileString + coordString
        
        guard var urlComponents = URLComponents(string: pathString) else { return nil }
        var contourString = "\(contourIntervals[0])"
        contourIntervals.forEach{ contourString += ",\($0)" }
        urlComponents.queryItems = [
            URLQueryItem(name:"contour_minutes", value: contourString),
            URLQueryItem(name:"access_token", value: self.mapboxToken)
        ]
        
        return urlComponents.url
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
    
    func queryURLFor(origins: [Coordinate], destinations: [Coordinate], travelMode: TravelMode) -> URL? {
        
        guard var urlComponents = URLComponents(string: gmapsMatrixURLString) else { return nil }
        
        let originsString = batchCoordinateStringsFrom(coords: origins)
        let destinationsString = batchCoordinateStringsFrom(coords: destinations)
        
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
    
    func batchCoordinateStringsFrom(coords: [Coordinate]) -> String {
        var str = ""
        for (index, c) in coords.enumerated() {
            str += "\(c.lat), \(c.lon)"
            if index < coords.endIndex {
                str += "|"
            }
        }
        return str
    }

}
