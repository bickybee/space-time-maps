//
//  QueryService.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-17.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation


class QueryService {
    
    typealias RouteQueryResultHandler = (Route?) -> ()
    
    let session = URLSession(configuration: .default)
    var apiKey: String?

    func getRoute(_ fromPlaceID: String, _ toPlaceID: String, _ waypointIDs: [String]?, _ travelMode: TravelMode, _ callback: @escaping RouteQueryResultHandler) {
        
        if var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/directions/json") {
            
            urlComponents.queryItems = [
                URLQueryItem(name:"origin", value:"place_id:\(fromPlaceID)"),
                URLQueryItem(name:"destination", value:"place_id:\(toPlaceID)"),
                URLQueryItem(name:"mode", value: travelMode.rawValue),
                URLQueryItem(name:"key", value:"\(self.apiKey!)")
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
                        let legs = firstRoute.legs
                        var durationInSeconds = 0
                        for leg in legs {
                            durationInSeconds += leg.duration.value
                        }
                        let route = Route(polyline: line, duration: durationInSeconds)
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

