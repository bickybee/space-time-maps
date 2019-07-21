//
//  Place.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-18.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps
import MobileCoreServices

struct Coordinate : Codable {
    let latitude, longitude: Double
    
    static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return (lhs.latitude == rhs.latitude) && (lhs.longitude == rhs.longitude)
    }
}

final class Place : NSObject, Codable {
    
    let name: String
    let coordinate: Coordinate
    let placeID: String
    //    let address: String
    
    override var description: String {
        return "Place: name: \(name), coordinate: \(coordinate), placeID: \(placeID))"
    }
    
    init(_ name: String, _ placeID: String, _ latitude: Double, _ longitude: Double) {
        self.name = name
        self.placeID = placeID
        self.coordinate = Coordinate(latitude: latitude, longitude: longitude)
    }
    
    init(_ name: String, _ placeID: String, _ coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.placeID = placeID
        self.coordinate = Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
}

// MARK - For Drag and Drop functionality

extension Place: NSItemProviderWriting, NSItemProviderReading {
    
    static var writableTypeIdentifiersForItemProvider: [String]{
        return [(kUTTypeData as String)]
    }
    
    static var readableTypeIdentifiersForItemProvider: [String]{
        return [(kUTTypeData as String)]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        let progress = Progress(totalUnitCount: 100)
        do {
            let data = try JSONEncoder().encode(self)
            progress.completedUnitCount = 100
            completionHandler(data,nil)
        }
        catch {
            completionHandler(nil,error)
        }
        return progress
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Place {
        do {
            let subject = try JSONDecoder().decode(Place.self, from: data)
            return subject
        }
        catch{
            fatalError("\(error.localizedDescription)")
        }
    }

    
}
