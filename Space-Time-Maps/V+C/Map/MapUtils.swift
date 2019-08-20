//
//  MapUtils.swift
//  Space-Time-Maps
//
//  Created by Vicky on 15/08/2019.
//  Copyright © 2019 vicky. All rights reserved.
//

import Foundation
import GoogleMaps

class MapUtils {
    
    // Weirdly separated dest vs. non-dest functions cuz of weird dumb implementation decisions elsewhere lol
    
    // Destination places get coloured via gradient
    public static func markersForDestinationPlaces(_ places : [Place]) -> [GMSMarker] {
        
        guard places.count > 0 else { return [] }
        var markers = [GMSMarker]()
        let maxIndex = places.count - 1
        
        for index in 0...maxIndex {
            let marker = markerFor(place: places[index])
            let colour = ColorUtils.colorFor(index: index, outOf: maxIndex)
            marker.icon = GMSMarker.markerImage(with: colour)
            markers.append(marker)
        }
        
        return markers
    }
    
    // Non-destination places are grey
    public static func markersForNonDestinationPlaces(_ places : [Place]) -> [GMSMarker] {
        
        guard places.count > 0 else { return [] }
        var markers = [GMSMarker]()
        
        for place in places {
            let marker = markerFor(place: place)
            marker.icon = GMSMarker.markerImage(with: .lightGray)
            markers.append(marker)
        }
        
        return markers
    }
    
    public static func polylinesForRouteLegs(_ legs : [Leg]) -> [GMSPolyline] {
        
        guard legs.count > 0 else { return [] }
        let maxIndex = legs.count - 1
        var polylines = [GMSPolyline]()
        
        for index in 0...maxIndex {
            let polyline = polylineFor(encodedPath: legs[index].polyline)
            polyline.spans = gradientStyleForPolyline(at: index, outOf: maxIndex + 1) // want color to incl. same range as places, of which there are always 1 more
            polylines.append(polyline)
        }
        
        return polylines
        
    }
    
}

private extension MapUtils {
    
    static let strokeWidth : CGFloat = 3.0
    
    static func markerFor(place: Place) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: place.coordinate.lat, longitude: place.coordinate.lon)
        marker.title = place.name
        return marker
    }
    
    static func polylineFor(encodedPath: String) -> GMSPolyline {
        let path = GMSPath(fromEncodedPath: encodedPath)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = strokeWidth
        return polyline
    }
    
    static func gradientStyleForPolyline(at index: Int, outOf maxIndex: Int) -> [GMSStyleSpan] {
        let gradient = ColorUtils.gradientFor(index: index, outOf: maxIndex)
        let style = GMSStrokeStyle.gradient(from: gradient.0, to: gradient.1)
        return [GMSStyleSpan(style: style)]
    }
    
}
