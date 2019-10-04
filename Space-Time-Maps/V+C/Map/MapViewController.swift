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
        
        // Set our view to be the map
        view = mapView
        //refreshMarkup()
        
    }
    
    // Parent should respond to user input, eventually trickle down only what should be rendered
//    override func didMove(toParent parent: UIViewController?) {
//        self.mapView.delegate = parent as? GMSMapViewDelegate
//    }
    
    // Refresh all map markup
    func refreshMarkup(placeGroups: [PlaceGroup], routeLegs: [Leg]?) {
        
        // Setup fresh map
        mapView.clear()
        var allOverlays : [GMSOverlay]
        
        let destinationMarkers = MapUtils.markersForPlaceGroups(placeGroups)
        
        // Wrap map to markers
        let allMarkers = destinationMarkers
        mapView.wrapBoundsTo(markers: allMarkers)
        
        // Get polylines for route legs
        if let legs = routeLegs {
            let polylines = MapUtils.polylinesForRouteLegs(legs)
            allOverlays = allMarkers + polylines
        } else {
            allOverlays = allMarkers
        }
        
        // Add all overlays to map
        mapView.add(overlays: allOverlays)
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

protocol MapViewControllerDelegate : AnyObject {
    
    func mapViewController(_ mapViewController: MapViewController, didUpdateBounds bounds: GMSCoordinateBounds)
    
}

extension MapViewController : GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        let visibleRegion = mapView.projection.visibleRegion()
        let bounds = GMSCoordinateBounds(region: visibleRegion)
        delegate?.mapViewController(self, didUpdateBounds: bounds)
    }
    
}
