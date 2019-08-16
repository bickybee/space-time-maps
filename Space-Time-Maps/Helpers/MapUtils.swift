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

    private static let strokeWidth : CGFloat = 3.0
    
    public static func polylinesForRouteLegs(_ legs : [Leg]) -> [GMSPolyline] {
        
        guard legs.count > 0 else { return [] }
        let maxIndex = legs.count - 1
        var polylines = [GMSPolyline]()
        
        for index in 0...maxIndex {
            let polyline = polylineFor(encodedPath: legs[index].polyline)
            polyline.spans = gradientStyleForPolyline(at: index, outOf: maxIndex)
            polylines.append(polyline)
        }
        
        return polylines
        
    }
    
    public static func markersForDestinationPlaces(_ places : [Place]) -> [GMSMarker] {
        
        guard places.count > 0 else { return [] }
        var markers = [GMSMarker]()
        let maxIndex = places.count - 1
        
        for index in 0...maxIndex {
            let colour = ColorUtils.colorFor(index: index, outOf: maxIndex)
            let marker = markerFor(place: places[index])
            marker.icon = GMSMarker.markerImage(with: colour)
            markers.append(marker)
        }
        
        return markers
    }
    
    public static func markersForNonDestinationPlaces(_ places : [Place]) -> [GMSMarker] {
        var markers = [GMSMarker]()
        
        for place in places {
            let marker = markerFor(place: place)
            marker.icon = GMSMarker.markerImage(with: .gray)
            markers.append(marker)
        }
        
        return markers
    }
    
    private static func markerFor(place: Place) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: place.coordinate.lat, longitude: place.coordinate.lon)
        marker.title = place.name
        return marker
    }
    
    private static func polylineFor(encodedPath: String) -> GMSPolyline {
        let path = GMSPath(fromEncodedPath: encodedPath)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = strokeWidth
        return polyline
    }
    
    private static func gradientStyleForPolyline(at index: Int, outOf maxIndex: Int) -> [GMSStyleSpan] {
        let gradient = ColorUtils.gradientFor(index: index, outOf: maxIndex)
        let style = GMSStrokeStyle.gradient(from: gradient.0, to: gradient.1)
        return [GMSStyleSpan(style: style)]
    }
    
    
}
