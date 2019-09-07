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
    
    public static func markersForPlaceGroups(_ placeGroups : [PlaceGroup]) -> [GMSMarker] {
        
        var markers = [GMSMarker]()
        
        for (i, group) in placeGroups.enumerated() {
            markers.append(contentsOf: markersForPlaces(group.places, withShadow: i == 0 ? nil : .black))
        }
        
        return markers
    }

    
    // Destination places get coloured via gradient
    public static func markersForPlaces(_ places : [Place], withShadow shadowColor: UIColor? ) -> [GMSMarker] {
        
        guard places.count > 0 else { return [] }
        var markers = [GMSMarker]()
        let maxIndex = places.count - 1
        
        for index in 0...maxIndex {
            let marker = markerFor(place: places[index])
            let colour = places[index].color
            let iconView = shadowColor != nil ? UIImageView(image: shadowedIcon(with: colour, shadowColor: .black)) : UIImageView(image: nonShadowedIcon(with: colour))
            marker.iconView = iconView
            markers.append(marker)
        }
        
        return markers
    }
    
    private static func shadowedIcon(with color: UIColor, shadowColor: UIColor) -> UIImage {
        let bottomImage = GMSMarker.markerImage(with: shadowColor)
        let topImage = GMSMarker.markerImage(with: color)
        
        let size = CGSize(width: topImage.size.width * 1.1, height: topImage.size.height * 1.1)
        UIGraphicsBeginImageContext(size)
        
        let shadowSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        bottomImage.draw(in: shadowSize, blendMode: .normal, alpha: 0.75)
        
        let drawSize = CGRect(x: 3, y: 4, width: size.width - 6, height: size.height - 8)
        topImage.draw(in: drawSize)
        
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private static func nonShadowedIcon(with color: UIColor) -> UIImage {
        let topImage = GMSMarker.markerImage(with: color)
        
        let size = CGSize(width: topImage.size.width * 1.1, height: topImage.size.height * 1.1)
        UIGraphicsBeginImageContext(size)

        let drawSize = CGRect(x: 3, y: 4, width: size.width - 6, height: size.height - 8)
        topImage.draw(in: drawSize)
        
        let newImage : UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
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
//            let startFraction = Double(index) / Double(maxIndex + 1)
//            let endFraction = Double(index + 1) / Double(maxIndex + 1)
            polyline.spans = [GMSStyleSpan(style: GMSStrokeStyle.gradient(from: legs[index].gradient[0], to: legs[index].gradient[1]))]
            polylines.append(polyline)
        }
        
        return polylines
        
    }
    
}

private extension MapUtils {
    
    static let strokeWidth : CGFloat = 3.0
    
    static func markerFor(place: Place) -> GMSMarker {
        let marker = GMSMarker()
        marker.layer.borderWidth = 2
        marker.layer.borderColor = UIColor.red.cgColor
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
    
    static func gradientStyleForPolyline(startFraction: Double, endFraction: Double) -> [GMSStyleSpan] {
        let gradient = ColorUtils.gradientFor(startFraction: startFraction, endFraction: endFraction)
        let style = GMSStrokeStyle.gradient(from: gradient.0, to: gradient.1)
        return [GMSStyleSpan(style: style)]
    }
    
}
