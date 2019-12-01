//
//  GMapViewController.swift
//  Space-Time-Maps
//
//  Created by vicky on 2019-07-21.
//  Copyright © 2019 vicky. All rights reserved.
//
//  MapViewController: responsible for rendering Google Maps and overlays to the map.

import UIKit
import GoogleMaps
import GooglePlaces

class MapViewController: UIViewController {

    var mapView : GMSMapView!
    let defaultLocation = CLLocation(latitude: 43.6532, longitude: -79.3832) // Toronto
    let defaultZoom: Float = 13.0
    var overlays = [GMSOverlay]()
    
    var markers = [GMSMarker]()
    var timeQueryMarker : GMSTimeMarker?
    
    weak var delegate : MapViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create a map.
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: defaultZoom)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        mapView.setMinZoom(mapView.minZoom, maxZoom: Float(16.0))
        
        //Style map w/ json file
        do {
            if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            }
        } catch {
            NSLog("Failed to load style.")
        }
        
        // Subscribe to location updates
        NotificationCenter.default.addObserver(self, selector: #selector(onDidUpdateLocation(_:)), name: .didUpdateLocation, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onDidTapDest), name: .didTapMarker, object: nil)
        
        // Set our view to be the map
        view = mapView
    }

    @objc func onDidTapDest(_ notification: Notification) {
        let placeName = notification.object as! String
        guard let marker = markers.first(where:{ $0.title! == placeName } ) else { return }
        mapView.selectedMarker = marker
        mapView.moveCameraTo(latitude: marker.position.latitude, longitude: marker.position.longitude)
    }
    
    // Parent should respond to user input, eventually trickle down only what should be rendered
//    override func didMove(toParent parent: UIViewController?) {
//        self.mapView.delegate = parent as? GMSMapViewDelegate
//    }
    
    // Refresh all map markup
    func refreshMarkup(placeGroups: [PlaceGroup], itinerary: Itinerary) {
        
        // Setup fresh map
        mapView.clear()
        // Wrap map to markers
        markers = MapUtils.markersForPlacesIn(placeGroups, itinerary)
        mapView.wrapBoundsTo(markers: markers)
        
        let routeLegs = itinerary.route.legs
        mapView.add(overlays: MapUtils.polylinesForRouteLegs(routeLegs))
        mapView.add(overlays: MapUtils.ticksForRouteLegs(routeLegs))
        let ticks = MapUtils.ticksForRouteLegs(routeLegs)
        print(ticks[safe: 0])
        print(ticks.count)
        mapView.add(overlays: markers)
    }
    
    // Respond to notification updates by displaying current location on the map
    @objc func onDidUpdateLocation(_ notification: Notification) {
        if let location = notification.userInfo?["location"] as? CLLocation {
            mapView.moveCameraTo(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

        } else {
            print("Could not unwrap notification")
        }
    }

}

extension MapViewController : TimeQueryDelegate {
    func didMakeTimeQuery(time: TimeInterval, schedulable: Schedulable?) {
        if let dest = schedulable as? Destination {
            // Update marker
            if let marker = timeQueryMarker {
                marker.pos = dest.place.coordinate
                marker.time = time
                marker.color = dest.place.color
            } else {
                let marker = GMSTimeMarker.markerWithPosition(dest.place.coordinate, time: time)
                marker.color = dest.place.color
                marker.map = mapView
                overlays.append(marker)
                timeQueryMarker = marker
            }
        } else if let leg = schedulable as? Leg {
            // Find position in leg
            var position : Coordinate
            var color : UIColor
            if leg.travelTiming.containsInclusive(time) {
                position = leg.coords[leg.coords.count / 2]
                color = .darkGray
            } else if Timing(start: leg.timing.start, end: leg.travelTiming.start).containsInclusive(time) {
                position = leg.coords[0]
                color = .gray
            } else {
                position = leg.coords[leg.coords.count - 1]
                color = .gray
            }
            // Update marker
            if let marker = timeQueryMarker {
                marker.pos = position
                marker.time = time
                marker.color = color
            } else {
                let marker = GMSTimeMarker.markerWithPosition(position, time: time)
                marker.color = color
                marker.map = mapView
                overlays.append(marker)
                timeQueryMarker = marker
            }
        } else {
            removeTimeQueryMarker()
        }
    }

    func didEndTimeQuery() {
        removeTimeQueryMarker()
    }
    
    func removeTimeQueryMarker() {
        if let marker = timeQueryMarker {
            overlays.removeAll(where: { $0 is GMSTimeMarker} )
            mapView.clear()
            mapView.add(overlays: overlays)
            marker.map = nil
            timeQueryMarker = nil
        }
    }
    
}

protocol MapViewControllerDelegate : AnyObject {
    
    func mapViewController(_ mapViewController: MapViewController, didUpdateBounds bounds: GMSCoordinateBounds)
    
}

extension MapViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        delegate?.mapViewController(self, didUpdateBounds: bounds)
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        NotificationCenter.default.post(name: Notification.Name.didTapMarker, object: marker.title)
        return false
    }
    
}

extension Notification.Name {
    static let didTapMarker = Notification.Name("didTapMarker")
}
