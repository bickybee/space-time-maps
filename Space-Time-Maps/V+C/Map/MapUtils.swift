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
    
    private static var paragraphStyle : NSMutableParagraphStyle {
        var style = NSMutableParagraphStyle()
        style.alignment = .center
        return style
    }
    
    private static let stringAttributes = [
        NSAttributedString.Key.paragraphStyle: paragraphStyle,
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 24.0),
        NSAttributedString.Key.foregroundColor: UIColor.white
    ]
    
    // Weirdly separated dest vs. non-dest functions cuz of weird dumb implementation decisions elsewhere lol
    
    public static func markersForPlacesIn(_ placeGroups : [PlaceGroup], _ itinerary: Itinerary) -> [GMSMarker] {
        
        var markers = [GMSMarker]()
        
        for group in placeGroups {
            markers.append(contentsOf: markersForPlaces(group.places, itinerary))
        }
        
        return markers
    }

    
    // Destination places get coloured via gradient
    public static func markersForPlaces(_ places : [Place], _ itinerary: Itinerary) -> [GMSMarker] {
        
        guard places.count > 0 else { return [] }
        var markers = [GMSMarker]()
        let maxIndex = places.count - 1
        
        for index in 0...maxIndex {
            let place = places[index]
            let marker = markerFor(place: places[index])
            let colour = place.color
            if let itineraryIndex = itinerary.destIndexOfPlaceWithName(place.name) {
                marker.icon = MapUtils.numberedIcon(with: colour, number: itineraryIndex + 1)
            } else {
                marker.icon = GMSMarker.markerImage(with: colour)
            }
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
    
    private static func numberedIcon(with color: UIColor, number: Int) -> UIImage {
        let markerImage = GMSMarker.markerImage(with: color)
        
        let size = CGSize(width: markerImage.size.width, height: markerImage.size.height)
        UIGraphicsBeginImageContext(size)
        
        let markerSize = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        markerImage.draw(in: markerSize)

        let str = NSAttributedString(string:(number).description, attributes: MapUtils.stringAttributes)
        str.draw(in: markerSize)
        
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
        var polylines = [GMSPolyline]()
        
        for leg in legs {
            let polyline = polylineFor(encodedPath: leg.polyline)
            let startColor = leg.startPlace.color
            let endColor = leg.endPlace.color
            polyline.spans = [GMSStyleSpan(style: GMSStrokeStyle.gradient(from: startColor, to: endColor))]
            polylines.append(polyline)
            if let isopath = leg.isochrone?.path {
                print(isopath.encodedPath())
                let isopoly = GMSPolyline(path: isopath)
                polylines.append(isopoly)
            }
        }
        
        return polylines
        
    }
    
    public static func ticksForRouteLegs (_ legs: [Leg]) -> [GMSCircle] {
        guard legs.count > 0 else { return [] }
        var circles = [GMSCircle]()
        
        for leg in legs {
            if let timeTicks = leg.ticks {
                circles.append(GMSCircle(position: timeTicks[0].coordinate, radius: 50))
            }
        }
        return circles
    }
    
    // Distance in metres
    public static func locationsAlongLeg(_ leg: Leg, ofDistance metres: CLLocationDistance) -> [Coordinate] {
        let path = GMSPath(fromEncodedPath: leg.polyline)!
        var locations = [Coordinate]()
        let coord0 = path.coordinate(at: 0)
        var lastLoc = CLLocation(latitude: coord0.latitude, longitude: coord0.longitude)
        
        for i in 1..<path.count() {
            let coord = path.coordinate(at: UInt(i))
            let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
            let diff = loc.distance(from: lastLoc)
            if diff >= metres {
                locations.append(coord)
                lastLoc = loc
            }
            
        }
 
        return locations
    }

    func locationAlongPath(_ path: GMSPath, at index: Double) -> CLLocation {
        let i0 = UInt(floor(index))
        let i1 = UInt(ceil(index))
        let c0 = path.coordinate(at: i0)
        let c1 = path.coordinate(at: i1)
        let frac = index - Double(i0)
        let lat = c0.latitude + (c1.latitude - c0.latitude) * frac
        let lon = c0.longitude + (c1.longitude - c0.longitude) * frac
        return CLLocation(latitude: lat, longitude: lon)
    }

    
}

private extension MapUtils {
    
    static let strokeWidth : CGFloat = 3.0
    
    static func markerFor(place: Place) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = place.coordinate
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
