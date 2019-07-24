//
//  QueryService.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-17.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation


class QueryService {
    
    typealias QueryResultHandler = (String?) -> ()
    
    let session = URLSession(configuration: .default)
    var apiKey: String?
    
    // Returns polyline
    func getRoute(_ fromPlaceID: String, _ toPlaceID: String, _ travelMode: TravelMode, _ callback: @escaping QueryResultHandler ) {
        
        if var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/directions/json") {
            
            urlComponents.queryItems = [
                URLQueryItem(name:"origin", value:"place_id:\(fromPlaceID)"),
                URLQueryItem(name:"destination", value:"place_id:\(toPlaceID)"),
                URLQueryItem(name:"mode", value: travelMode.rawValue),
                URLQueryItem(name:"key", value:"\(self.apiKey!)")
            ]
            
            guard let url = urlComponents.url else { return }
            
            let dataTask = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("ERROR")
                    print(error.localizedDescription)
                } else if let data = data {
                    print("SUCCESS")
                    let decoder = JSONDecoder()
                    let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data)
                    let aRoute = routeResponseObject?.routes[0]
                    let aLine = aRoute?.overviewPolyline.points
                    DispatchQueue.main.async {
                        callback(aLine)
                    }
                }
            }
            dataTask.resume()
        }
    }
    
    func getWaypointRoute(_ fromPlaceID: String, _ toPlaceID: String, _ waypointIDs: [String], _ travelMode: TravelMode, _ callback: @escaping QueryResultHandler) {
        
        if var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/directions/json") {
            
            var hits = 0
            var waypointString = ""
            for placeID in waypointIDs {
                waypointString += "|place_id:" + placeID
            }
            print(waypointString)
            urlComponents.queryItems = [
                URLQueryItem(name:"origin", value:"place_id:\(fromPlaceID)"),
                URLQueryItem(name:"destination", value:"place_id:\(toPlaceID)"),
                URLQueryItem(name:"waypoints", value:"optimize:true\(waypointString)"),
                URLQueryItem(name:"mode", value: travelMode.rawValue),
                URLQueryItem(name:"key", value:"\(self.apiKey!)")
            ]
            
            guard let url = urlComponents.url else { return }
            print(urlComponents.url!)
            
            let dataTask = session.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("ERROR")
                    print(error.localizedDescription)
                } else if let data = data {
                    hits += 1
                    print("SUCCESS \(hits)")
                    let decoder = JSONDecoder()
                    let routeResponseObject = try? decoder.decode(RouteResponseObject.self, from: data)
                    let aRoute = routeResponseObject?.routes[0]
                    let aLine = aRoute?.overviewPolyline.points
                    print("RESPONSE ?")
                    DispatchQueue.main.async {
                        callback(aLine)
                    }
                }
            }
            dataTask.resume()
        }
        
    }

    
}

